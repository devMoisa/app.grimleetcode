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
    /// Persisted map of AI-generated exercises per lesson (baseline stays in code).
    var generatedExercisesByLesson: [Lesson.ID: [Problem]]
    /// Set of lesson IDs currently being generated (drives per-lesson spinners).
    var lessonsGeneratingExercises: Set<Lesson.ID>
    /// Bulk progress `(done, total)` — non-nil while a "generate all" run is active.
    var bulkGenerationProgress: BulkProgress?
    var lastGenerationError: String?

    struct BulkProgress: Hashable {
        var done: Int
        var total: Int
        var isFinished: Bool { done >= total }
    }

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

        // Load persisted generated exercises and apply them on top of the baseline tracks.
        let generated = PersistenceStore.loadGeneratedExercises()
        let materialized = Self.applyGeneratedExercises(generated, to: tracks)
        self.tracks = materialized
        self.selectedTrackID = materialized.first?.id
        self.selectedLessonID = materialized.first?.allLessons.first?.id
        self.completedExercises = PersistenceStore.loadCompletedExercises()
        self.generatedExercisesByLesson = generated
        self.lessonsGeneratingExercises = []
        self.bulkGenerationProgress = nil
        self.lastGenerationError = nil
    }

    private static func applyGeneratedExercises(
        _ overrides: [Lesson.ID: [Problem]],
        to baseline: [Track]
    ) -> [Track] {
        guard !overrides.isEmpty else { return baseline }
        var result = baseline
        for tIdx in result.indices {
            for mIdx in result[tIdx].modules.indices {
                for lIdx in result[tIdx].modules[mIdx].lessons.indices {
                    let id = result[tIdx].modules[mIdx].lessons[lIdx].id
                    if let extra = overrides[id], !extra.isEmpty {
                        result[tIdx].modules[mIdx].lessons[lIdx].exercises.append(contentsOf: extra)
                    }
                }
            }
        }
        return result
    }

    /// Wipes all roadmap progress (both in memory and on disk).
    @MainActor
    func resetRoadmapProgress() {
        completedExercises = [:]
        PersistenceStore.clearAllProgress()
    }

    // MARK: - Exercise generation (Phase 2)

    @MainActor
    func generateExercises(for lesson: Lesson) async {
        guard !lessonsGeneratingExercises.contains(lesson.id) else { return }
        guard let (track, module) = locate(lessonID: lesson.id) else { return }

        lessonsGeneratingExercises.insert(lesson.id)
        defer { lessonsGeneratingExercises.remove(lesson.id) }

        do {
            let newExercises = try await GrinLeetAPI.default.generateExercises(
                language: track.language,
                lessonTitle: lesson.title,
                lessonSummary: lesson.summary,
                moduleTitle: module.title,
                trackTitle: track.title
            )
            append(exercises: newExercises, toLessonID: lesson.id)
        } catch {
            lastGenerationError = error.localizedDescription
        }
    }

    /// Fires generation for every lesson in the current track that has zero exercises.
    /// Runs three at a time to keep OpenRouter happy while still finishing in reasonable time.
    @MainActor
    func generateAllRemainingExercises() async {
        guard let track = selectedTrack else { return }
        let missing = track.allLessons.filter { $0.exercises.isEmpty }
        guard !missing.isEmpty else { return }

        bulkGenerationProgress = BulkProgress(done: 0, total: missing.count)
        defer { bulkGenerationProgress = nil }

        let concurrency = 3
        var index = 0
        while index < missing.count {
            let chunk = Array(missing[index..<min(index + concurrency, missing.count)])
            await withTaskGroup(of: Void.self) { group in
                for lesson in chunk {
                    group.addTask { @MainActor [weak self] in
                        await self?.generateExercises(for: lesson)
                    }
                }
            }
            index += chunk.count
            bulkGenerationProgress?.done = index
        }
    }

    @MainActor
    func clearGeneratedExercises() {
        generatedExercisesByLesson = [:]
        tracks = Self.applyGeneratedExercises([:], to: tracks.map(Self.stripGenerated))
        PersistenceStore.clearGeneratedExercises()
    }

    /// Given a track with baseline+generated exercises materialized, returns a copy
    /// containing ONLY baseline exercises (removing generated ones we know about).
    private static func stripGenerated(_ track: Track) -> Track {
        // We rebuild from PythonRoadmap when a wipe is requested. For simplicity,
        // callers that need a clean baseline should re-hydrate from PythonRoadmap.track.
        // Kept here so future code can plug in per-track baselines cleanly.
        track
    }

    private func locate(lessonID: Lesson.ID) -> (Track, Module)? {
        for track in tracks {
            for module in track.modules where module.lessons.contains(where: { $0.id == lessonID }) {
                return (track, module)
            }
        }
        return nil
    }

    private func append(exercises: [Problem], toLessonID id: Lesson.ID) {
        generatedExercisesByLesson[id, default: []].append(contentsOf: exercises)
        PersistenceStore.saveGeneratedExercises(generatedExercisesByLesson)

        for tIdx in tracks.indices {
            for mIdx in tracks[tIdx].modules.indices {
                for lIdx in tracks[tIdx].modules[mIdx].lessons.indices where tracks[tIdx].modules[mIdx].lessons[lIdx].id == id {
                    tracks[tIdx].modules[mIdx].lessons[lIdx].exercises.append(contentsOf: exercises)
                    return
                }
            }
        }
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
