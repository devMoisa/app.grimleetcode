import Foundation

enum ProgrammingLanguage: String, Codable, CaseIterable, Identifiable, Hashable {
    case python = "Python"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case c = "C"
    case swift = "Swift"

    var id: String { rawValue }

    /// Identifier used by Monaco Editor for syntax highlighting.
    var monacoID: String {
        switch self {
        case .python: "python"
        case .javascript: "javascript"
        case .typescript: "typescript"
        case .c: "c"
        case .swift: "swift"
        }
    }

    var fileExtension: String {
        switch self {
        case .python: "py"
        case .javascript: "js"
        case .typescript: "ts"
        case .c: "c"
        case .swift: "swift"
        }
    }

    var starterCode: String {
        switch self {
        case .python:
            """
            def solution():
                pass


            if __name__ == "__main__":
                print(solution())
            """
        case .javascript:
            """
            function solution() {
                // your code here
            }

            console.log(solution());
            """
        case .typescript:
            """
            function solution(): unknown {
                // your code here
                return null;
            }

            console.log(solution());
            """
        case .c:
            """
            #include <stdio.h>

            int main(void) {
                // your code here
                return 0;
            }
            """
        case .swift:
            """
            func solution() -> Any {
                // your code here
                return 0
            }

            print(solution())
            """
        }
    }
}
