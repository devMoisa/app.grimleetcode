import Foundation

struct ExecutionResult: Identifiable, Hashable {
    let id: UUID = UUID()
    var status: Status
    var stdout: String
    var stderr: String
    var verdict: String?
    var executionTimeMs: Int?

    enum Status: String, Hashable {
        case success
        case failed
        case running
        case error
    }
}
