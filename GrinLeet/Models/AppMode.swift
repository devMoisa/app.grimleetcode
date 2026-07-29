import Foundation

enum AppMode: String, CaseIterable, Identifiable, Codable, Hashable {
    case problems
    case roadmap

    var id: String { rawValue }

    var label: String {
        switch self {
        case .problems: "Problems"
        case .roadmap: "Roadmap"
        }
    }

    var systemImage: String {
        switch self {
        case .problems: "list.bullet.rectangle"
        case .roadmap: "map"
        }
    }
}
