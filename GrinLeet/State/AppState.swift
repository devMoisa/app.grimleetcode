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

    /// Mock "run" — replace with local Python/PythonKit or FastAPI call later.
    @MainActor
    func runCurrentCode() async {
        isRunning = true
        defer { isRunning = false }
        try? await Task.sleep(for: .milliseconds(600))
        lastResult = ExecutionResult(
            status: .success,
            stdout: "Mock stdout for \(selectedLanguage.rawValue).\n(Wire this to PythonKit / FastAPI to make it real.)",
            stderr: "",
            verdict: nil,
            executionTimeMs: 42
        )
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
