import Foundation
import Observation

@Observable
final class AppState {
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

    init(
        problems: [Problem] = MockData.problems,
        language: ProgrammingLanguage = .python
    ) {
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
    }

    var selectedProblem: Problem? {
        guard let id = selectedProblemID else { return nil }
        return problems.first(where: { $0.id == id })
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
            lastResult = try await GrinLeetAPI.default.verifyCode(
                problem: problem,
                language: selectedLanguage,
                code: currentCode
            )
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
