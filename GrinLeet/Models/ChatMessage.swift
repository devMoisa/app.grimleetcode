import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable, Hashable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var content: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}
