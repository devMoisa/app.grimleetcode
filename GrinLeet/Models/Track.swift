import Foundation

struct Track: Identifiable, Codable, Hashable {
    let id: UUID
    var language: ProgrammingLanguage
    var title: String
    var subtitle: String
    var modules: [Module]

    var allLessons: [Lesson] {
        modules.flatMap { $0.lessons }
    }

    var lessonCount: Int { allLessons.count }

    func module(containing lessonID: Lesson.ID) -> Module? {
        modules.first { $0.lessons.contains(where: { $0.id == lessonID }) }
    }

    func lesson(with id: Lesson.ID) -> Lesson? {
        allLessons.first { $0.id == id }
    }

    func exercise(with id: Problem.ID) -> Problem? {
        for lesson in allLessons {
            if let ex = lesson.exercises.first(where: { $0.id == id }) {
                return ex
            }
        }
        return nil
    }
}

struct Module: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var summary: String
    var lessons: [Lesson]
}

struct Lesson: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var summary: String
    /// Markdown theory content. Empty string means "not generated yet" (Phase 2).
    var theory: String
    var exercises: [Problem]

    var isStub: Bool { theory.isEmpty }
}
