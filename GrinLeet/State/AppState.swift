import Foundation
import Observation

@Observable
final class AppState {
    var mode: AppMode
    var problems: [Problem]
    var selectedProblemID: Problem.ID?
    var selectedLanguage: ProgrammingLanguage
    var currentCode: String
    var isRunning: Bool
    var lastResult: ExecutionResult?
    var isGeneratorPresented: Bool

    // Chatcode
    var isChatOpen: Bool
    var chatMessagesByProblem: [Problem.ID: [ChatMessage]]
    var isChatSending: Bool
    var chatError: String?

    // Roadmap
    var tracks: [Track]
    var selectedTrackID: Track.ID?
    var selectedLessonID: Lesson.ID?
    /// Exercise IDs that have passed /verify (mapped to their lesson).
    var completedExercises: [Lesson.ID: Set<Problem.ID>]

    init(
        problems: [Problem] = MockData.problems,
        tracks: [Track] = [PythonRoadmap.track],
        language: ProgrammingLanguage = .python
    ) {
        self.mode = .problems
        self.problems = problems
        self.selectedProblemID = problems.first?.id
        self.selectedLanguage = language
        self.currentCode = language.starterCode
        self.isRunning = false
        self.lastResult = nil
        self.isGeneratorPresented = false
        self.isChatOpen = false
        self.chatMessagesByProblem = [:]
        self.isChatSending = false
        self.chatError = nil
        self.tracks = tracks
        self.selectedTrackID = tracks.first?.id
        self.selectedLessonID = tracks.first?.allLessons.first?.id
        self.completedExercises = PersistenceStore.loadCompletedExercises()
    }

    /// Wipes all roadmap progress (both in memory and on disk).
    @MainActor
    func resetRoadmapProgress() {
        completedExercises = [:]
        PersistenceStore.clearAllProgress()
    }

    // MARK: - Unified resolver

    var selectedProblem: Problem? {
        guard let id = selectedProblemID else { return nil }
        if let p = problems.first(where: { $0.id == id }) { return p }
        for track in tracks {
            if let ex = track.exercise(with: id) { return ex }
        }
        return nil
    }

    // MARK: - Roadmap helpers

    var selectedTrack: Track? {
        guard let id = selectedTrackID else { return tracks.first }
        return tracks.first(where: { $0.id == id })
    }

    var selectedLesson: Lesson? {
        guard let id = selectedLessonID else { return nil }
        return selectedTrack?.lesson(with: id)
    }

    func isExerciseCompleted(lessonID: Lesson.ID, exerciseID: Problem.ID) -> Bool {
        completedExercises[lessonID]?.contains(exerciseID) ?? false
    }

    func isLessonCompleted(_ lesson: Lesson) -> Bool {
        guard !lesson.exercises.isEmpty else { return false }
        let done = completedExercises[lesson.id] ?? []
        return lesson.exercises.allSatisfy { done.contains($0.id) }
    }

    /// Returns (completed, total) exercise count for a lesson.
    func progress(for lesson: Lesson) -> (Int, Int) {
        let done = completedExercises[lesson.id] ?? []
        let hit = lesson.exercises.filter { done.contains($0.id) }.count
        return (hit, lesson.exercises.count)
    }

    /// Returns (completed lessons, total lessons) for a module.
    func progress(for module: Module) -> (Int, Int) {
        let hit = module.lessons.filter { isLessonCompleted($0) }.count
        return (hit, module.lessons.count)
    }

    /// The lesson currently containing `selectedProblemID`, if any.
    func lessonContainingSelectedProblem() -> Lesson? {
        guard let pid = selectedProblemID else { return nil }
        for track in tracks {
            for lesson in track.allLessons where lesson.exercises.contains(where: { $0.id == pid }) {
                return lesson
            }
        }
        return nil
    }

    func selectExercise(_ exercise: Problem, in lesson: Lesson) {
        selectedProblemID = exercise.id
        selectedLessonID = lesson.id
        currentCode = selectedLanguage.starterCode
        lastResult = nil
    }

    var currentChatMessages: [ChatMessage] {
        guard let id = selectedProblemID else { return [] }
        return chatMessagesByProblem[id] ?? []
    }

    func resetCodeToStarter() {
        currentCode = selectedLanguage.starterCode
        lastResult = nil
    }

    /// Executes the current code against the FastAPI backend.
    @MainActor
    func runCurrentCode() async {
        isRunning = true
        defer { isRunning = false }
        do {
            lastResult = try await GrinLeetAPI.default.runCode(
                language: selectedLanguage,
                code: currentCode
            )
        } catch {
            lastResult = ExecutionResult(
                status: .error,
                stdout: "",
                stderr: error.localizedDescription,
                verdict: "Could not reach backend.",
                executionTimeMs: nil
            )
        }
    }

    /// Sends a user message to Chatcode about the currently selected problem.
    @MainActor
    func sendChatMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isChatSending else { return }
        guard let problem = selectedProblem else { return }
        let problemID = problem.id

        chatError = nil
        let userMsg = ChatMessage(role: .user, content: trimmed)
        chatMessagesByProblem[problemID, default: []].append(userMsg)
        let historyForRequest = chatMessagesByProblem[problemID] ?? []

        isChatSending = true
        defer { isChatSending = false }
        do {
            let reply = try await GrinLeetAPI.default.chat(
                problem: problem,
                history: historyForRequest
            )
            chatMessagesByProblem[problemID, default: []].append(reply)
        } catch {
            chatError = error.localizedDescription
        }
    }

    @MainActor
    func clearChatForCurrentProblem() {
        guard let id = selectedProblemID else { return }
        chatMessagesByProblem[id] = []
        chatError = nil
    }

    /// Submits the current code to the AI judge via /verify.
    @MainActor
    func submitCurrentCode() async {
        guard let problem = selectedProblem else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            let result = try await GrinLeetAPI.default.verifyCode(
                problem: problem,
                language: selectedLanguage,
                code: currentCode
            )
            lastResult = result
            if result.status == .success, let lesson = lessonContainingSelectedProblem() {
                completedExercises[lesson.id, default: []].insert(problem.id)
                PersistenceStore.saveCompletedExercises(completedExercises)
            }
        } catch {
            lastResult = ExecutionResult(
                status: .error,
                stdout: "",
                stderr: error.localizedDescription,
                verdict: "Could not reach backend for AI verdict.",
                executionTimeMs: nil
            )
        }
    }
}
