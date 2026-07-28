import SwiftUI

enum Difficulty: String, Codable, CaseIterable, Identifiable, Hashable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .easy: .green
        case .medium: .orange
        case .hard: .red
        }
    }
}
