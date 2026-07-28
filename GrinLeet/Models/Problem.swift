import Foundation

struct Problem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var difficulty: Difficulty
    var tags: [String]
    var statement: String
    var examples: [Example]
    var constraints: [String]
    var createdAt: Date

    struct Example: Codable, Hashable, Identifiable {
        var id: UUID = UUID()
        var input: String
        var output: String
        var explanation: String?
    }
}
