import Foundation

/// Small typed wrapper around `UserDefaults` for state we want to survive app relaunches.
/// Currently only stores roadmap exercise completions; grow as needed (code drafts,
/// chat history, last-selected lesson, generated problems, etc).
enum PersistenceStore {
    private static let defaults = UserDefaults.standard
    private static let completedExercisesKey = "grinleet.completedExercises.v1"
    private static let generatedExercisesKey = "grinleet.generatedExercises.v1"

    // MARK: - Roadmap completions

    static func loadCompletedExercises() -> [UUID: Set<UUID>] {
        guard
            let data = defaults.data(forKey: completedExercisesKey),
            let decoded = try? JSONDecoder().decode(CompletionsDTO.self, from: data)
        else {
            return [:]
        }
        return decoded.toDomain()
    }

    static func saveCompletedExercises(_ value: [UUID: Set<UUID>]) {
        let dto = CompletionsDTO(from: value)
        guard let data = try? JSONEncoder().encode(dto) else { return }
        defaults.set(data, forKey: completedExercisesKey)
    }

    static func clearAllProgress() {
        defaults.removeObject(forKey: completedExercisesKey)
    }

    // MARK: - Generated roadmap exercises (Phase 2)

    static func loadGeneratedExercises() -> [UUID: [Problem]] {
        guard
            let data = defaults.data(forKey: generatedExercisesKey),
            let decoded = try? JSONDecoder().decode(GeneratedExercisesDTO.self, from: data)
        else { return [:] }
        return decoded.toDomain()
    }

    static func saveGeneratedExercises(_ value: [UUID: [Problem]]) {
        let dto = GeneratedExercisesDTO(from: value)
        guard let data = try? JSONEncoder().encode(dto) else { return }
        defaults.set(data, forKey: generatedExercisesKey)
    }

    static func clearGeneratedExercises() {
        defaults.removeObject(forKey: generatedExercisesKey)
    }

    private struct GeneratedExercisesDTO: Codable {
        var byLesson: [String: [Problem]]

        init(from value: [UUID: [Problem]]) {
            byLesson = Dictionary(uniqueKeysWithValues: value.map { ($0.key.uuidString, $0.value) })
        }

        func toDomain() -> [UUID: [Problem]] {
            var result: [UUID: [Problem]] = [:]
            for (key, list) in byLesson {
                guard let id = UUID(uuidString: key) else { continue }
                result[id] = list
            }
            return result
        }
    }

    // MARK: - JSON DTO (UUID keys aren't JSON-native)

    private struct CompletionsDTO: Codable {
        var byLesson: [String: [String]]

        init(from value: [UUID: Set<UUID>]) {
            byLesson = Dictionary(uniqueKeysWithValues: value.map { lessonID, exerciseSet in
                (lessonID.uuidString, exerciseSet.map(\.uuidString).sorted())
            })
        }

        func toDomain() -> [UUID: Set<UUID>] {
            var result: [UUID: Set<UUID>] = [:]
            for (lessonKey, exerciseKeys) in byLesson {
                guard let lessonID = UUID(uuidString: lessonKey) else { continue }
                let ids = Set(exerciseKeys.compactMap(UUID.init(uuidString:)))
                if !ids.isEmpty {
                    result[lessonID] = ids
                }
            }
            return result
        }
    }
}
