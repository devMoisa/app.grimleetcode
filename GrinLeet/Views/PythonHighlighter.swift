import SwiftUI

/// Minimal, dependency-free Python syntax highlighter that emits an AttributedString
/// styled with Dracula colors — matching the Monaco editor's theme.
///
/// Not a full lexer: covers keywords, strings (including triple + prefixed like `f"..."`),
/// numbers, comments, decorators, dunder names, and common built-ins. Function and class
/// names get colored when they immediately follow `def` / `class`.
enum PythonHighlighter {
    static let recognizedAliases: Set<String> = ["python", "python3", "py", "py3", "python2"]

    static func highlight(_ source: String) -> AttributedString {
        let tokens = tokenize(source)
        var attributed = AttributedString()
        var cursor = source.startIndex

        for token in tokens {
            if token.range.lowerBound > cursor {
                var gap = AttributedString(source[cursor..<token.range.lowerBound])
                gap.foregroundColor = Palette.foreground
                attributed += gap
            }
            var part = AttributedString(source[token.range])
            part.foregroundColor = Palette.color(for: token.kind)
            attributed += part
            cursor = token.range.upperBound
        }

        if cursor < source.endIndex {
            var tail = AttributedString(source[cursor..<source.endIndex])
            tail.foregroundColor = Palette.foreground
            attributed += tail
        }

        attributed.font = .system(.callout, design: .monospaced)
        return attributed
    }

    // MARK: - Dracula palette

    enum Palette {
        static let foreground = Color(red: 248/255, green: 248/255, blue: 242/255)
        static let keyword    = Color(red: 255/255, green: 121/255, blue: 198/255)  // pink
        static let string     = Color(red: 241/255, green: 250/255, blue: 140/255)  // yellow
        static let comment    = Color(red:  98/255, green: 114/255, blue: 164/255)  // comment
        static let number     = Color(red: 189/255, green: 147/255, blue: 249/255)  // purple
        static let builtin    = Color(red: 139/255, green: 233/255, blue: 253/255)  // cyan
        static let function   = Color(red:  80/255, green: 250/255, blue: 123/255)  // green
        static let className  = Color(red: 139/255, green: 233/255, blue: 253/255)  // cyan
        static let decorator  = Color(red:  80/255, green: 250/255, blue: 123/255)  // green
        static let selfCls    = Color(red: 189/255, green: 147/255, blue: 249/255)  // purple
        static let magic      = Color(red:  80/255, green: 250/255, blue: 123/255)  // green

        static func color(for kind: Token.Kind) -> Color {
            switch kind {
            case .keyword:      keyword
            case .string:       string
            case .comment:      comment
            case .number:       number
            case .builtin:      builtin
            case .functionName: function
            case .className:    className
            case .decorator:    decorator
            case .selfCls:      selfCls
            case .magic:        magic
            }
        }
    }

    // MARK: - Token model

    struct Token {
        let range: Range<String.Index>
        let kind: Kind
        enum Kind { case keyword, string, comment, number, builtin, functionName, className, decorator, selfCls, magic }
    }

    private static let keywords: Set<String> = [
        "and", "as", "assert", "async", "await", "break", "class", "continue",
        "def", "del", "elif", "else", "except", "False", "finally", "for", "from",
        "global", "if", "import", "in", "is", "lambda", "None", "nonlocal", "not",
        "or", "pass", "raise", "return", "True", "try", "while", "with", "yield",
        "match", "case",
    ]

    private static let builtins: Set<String> = [
        "abs", "all", "any", "ascii", "bin", "bool", "bytearray", "bytes", "callable",
        "chr", "classmethod", "compile", "complex", "delattr", "dict", "dir", "divmod",
        "enumerate", "eval", "exec", "filter", "float", "format", "frozenset",
        "getattr", "globals", "hasattr", "hash", "help", "hex", "id", "input",
        "int", "isinstance", "issubclass", "iter", "len", "list", "locals",
        "map", "max", "memoryview", "min", "next", "object", "oct", "open",
        "ord", "pow", "print", "property", "range", "repr", "reversed", "round",
        "set", "setattr", "slice", "sorted", "staticmethod", "str", "sum",
        "super", "tuple", "type", "vars", "zip",
    ]

    private static let stringPrefixes: Set<Character> = ["f", "F", "r", "R", "b", "B", "u", "U"]

    // MARK: - Tokenizer

    private static func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var i = source.startIndex
        // Tracks the last non-trivial keyword so we can color the following identifier
        // as a function name (after `def`) or class name (after `class`).
        var pendingDeclaration: String?

        while i < source.endIndex {
            let c = source[i]

            // Newline / whitespace — just advance
            if c.isWhitespace {
                i = source.index(after: i)
                continue
            }

            // Line comment
            if c == "#" {
                let start = i
                while i < source.endIndex, source[i] != "\n" {
                    i = source.index(after: i)
                }
                tokens.append(Token(range: start..<i, kind: .comment))
                pendingDeclaration = nil
                continue
            }

            // String literal (with optional prefix)
            if isStringStart(source, at: i) {
                let start = i
                i = consumeString(source, from: i)
                tokens.append(Token(range: start..<i, kind: .string))
                pendingDeclaration = nil
                continue
            }

            // Number literal
            if c.isNumber {
                let start = i
                i = consumeNumber(source, from: i)
                tokens.append(Token(range: start..<i, kind: .number))
                pendingDeclaration = nil
                continue
            }

            // Decorator @name.qualified
            if c == "@" {
                let start = i
                i = source.index(after: i)
                while i < source.endIndex, isIdentifierBody(source[i]) || source[i] == "." {
                    i = source.index(after: i)
                }
                tokens.append(Token(range: start..<i, kind: .decorator))
                pendingDeclaration = nil
                continue
            }

            // Identifier / keyword
            if isIdentifierStart(c) {
                let start = i
                while i < source.endIndex, isIdentifierBody(source[i]) {
                    i = source.index(after: i)
                }
                let word = String(source[start..<i])

                if keywords.contains(word) {
                    tokens.append(Token(range: start..<i, kind: .keyword))
                    pendingDeclaration = (word == "def" || word == "class") ? word : nil
                } else if word == "self" || word == "cls" {
                    tokens.append(Token(range: start..<i, kind: .selfCls))
                    pendingDeclaration = nil
                } else if pendingDeclaration == "def" {
                    tokens.append(Token(range: start..<i, kind: .functionName))
                    pendingDeclaration = nil
                } else if pendingDeclaration == "class" {
                    tokens.append(Token(range: start..<i, kind: .className))
                    pendingDeclaration = nil
                } else if word.hasPrefix("__") && word.hasSuffix("__") && word.count >= 5 {
                    tokens.append(Token(range: start..<i, kind: .magic))
                    pendingDeclaration = nil
                } else if builtins.contains(word) {
                    tokens.append(Token(range: start..<i, kind: .builtin))
                    pendingDeclaration = nil
                } else {
                    pendingDeclaration = nil
                }
                continue
            }

            // Punctuation / operator — no token, just advance
            i = source.index(after: i)
            pendingDeclaration = nil
        }

        return tokens
    }

    // MARK: - Character classification

    private static func isIdentifierStart(_ c: Character) -> Bool {
        c == "_" || c.isLetter
    }

    private static func isIdentifierBody(_ c: Character) -> Bool {
        c == "_" || c.isLetter || c.isNumber
    }

    // MARK: - String literals

    private static func isStringStart(_ source: String, at i: String.Index) -> Bool {
        let c = source[i]
        if c == "\"" || c == "'" { return true }
        guard stringPrefixes.contains(c) else { return false }
        var j = source.index(after: i)
        if j < source.endIndex, stringPrefixes.contains(source[j]) {
            j = source.index(after: j)
        }
        return j < source.endIndex && (source[j] == "\"" || source[j] == "'")
    }

    private static func consumeString(_ source: String, from start: String.Index) -> String.Index {
        var i = start
        while i < source.endIndex, stringPrefixes.contains(source[i]) {
            i = source.index(after: i)
        }
        guard i < source.endIndex else { return i }
        let quote = source[i]

        // Triple-quoted?
        if let tripleEnd = tripleQuoteEnd(source, at: i, quote: quote) {
            var j = tripleEnd
            while j < source.endIndex {
                if let closing = tripleQuoteEnd(source, at: j, quote: quote) {
                    return closing
                }
                if source[j] == "\\", source.index(after: j) < source.endIndex {
                    j = source.index(j, offsetBy: 2)
                    continue
                }
                j = source.index(after: j)
            }
            return j
        }

        // Single-line string
        i = source.index(after: i)  // skip opening quote
        while i < source.endIndex {
            let ch = source[i]
            if ch == "\\", source.index(after: i) < source.endIndex {
                i = source.index(i, offsetBy: 2)
                continue
            }
            if ch == quote {
                return source.index(after: i)
            }
            if ch == "\n" { return i }
            i = source.index(after: i)
        }
        return i
    }

    /// If `source` at index `i` has three consecutive `quote` characters, returns the
    /// index just past them; otherwise nil.
    private static func tripleQuoteEnd(_ source: String, at i: String.Index, quote: Character) -> String.Index? {
        guard source.distance(from: i, to: source.endIndex) >= 3 else { return nil }
        let end3 = source.index(i, offsetBy: 3)
        if source[i..<end3].allSatisfy({ $0 == quote }) {
            return end3
        }
        return nil
    }

    // MARK: - Number literals

    private static func consumeNumber(_ source: String, from start: String.Index) -> String.Index {
        var i = start

        // Prefix like 0x / 0o / 0b
        if source[i] == "0", source.index(after: i) < source.endIndex {
            let next = source[source.index(after: i)]
            if "xXoObB".contains(next) {
                i = source.index(i, offsetBy: 2)
                while i < source.endIndex, source[i].isHexDigit || source[i] == "_" {
                    i = source.index(after: i)
                }
                return i
            }
        }

        while i < source.endIndex {
            let ch = source[i]
            if ch.isNumber || ch == "." || ch == "_" {
                i = source.index(after: i)
            } else if ch == "e" || ch == "E" {
                i = source.index(after: i)
                if i < source.endIndex, source[i] == "+" || source[i] == "-" {
                    i = source.index(after: i)
                }
            } else if ch == "j" || ch == "J" {
                i = source.index(after: i)  // complex literal suffix
                break
            } else {
                break
            }
        }
        return i
    }
}
