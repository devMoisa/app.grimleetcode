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
    }

    var selectedProblem: Problem? {
        guard let id = selectedProblemID else { return nil }
        return problems.first(where: { $0.id == id })
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

    /// Mock "submit" — replace with AI verdict call.
    @MainActor
    func submitCurrentCode() async {
        isRunning = true
        defer { isRunning = false }
        try? await Task.sleep(for: .milliseconds(900))
        lastResult = ExecutionResult(
            status: .success,
            stdout: "",
            stderr: "",
            verdict: "All example cases passed (mocked AI verdict).",
            executionTimeMs: nil
        )
    }
}
