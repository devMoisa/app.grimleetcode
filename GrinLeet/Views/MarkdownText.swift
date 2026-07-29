import SwiftUI

/// Renders a chat message that may include GitHub-style fenced code blocks.
///
/// - Text sections between fences are parsed as inline Markdown (bold, italic,
///   inline code, links). Whitespace and line breaks are preserved.
/// - Fenced code blocks (```lang\n...\n```) are rendered as separate monospaced
///   blocks with a language label and a dark background.
struct MarkdownText: View {
    let source: String
    var textColor: Color = .primary

    private var segments: [Segment] { Segment.parse(source) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(segments.indices, id: \.self) { i in
                switch segments[i] {
                case .text(let str):
                    inlineMarkdown(str)
                case .code(let code, let lang):
                    codeBlock(code, language: lang)
                }
            }
        }
    }

    // MARK: - Inline text

    @ViewBuilder
    private func inlineMarkdown(_ md: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: md,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            Text(attributed)
                .font(.callout)
                .foregroundStyle(textColor)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(md)
                .font(.callout)
                .foregroundStyle(textColor)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Code block

    private func codeBlock(_ code: String, language: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.caption2.weight(.semibold).monospaced())
                    .foregroundStyle(.tertiary)
            }
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Segmentation

    enum Segment: Hashable {
        case text(String)
        case code(String, String?)

        static func parse(_ source: String) -> [Segment] {
            var segments: [Segment] = []
            var textLines: [String] = []
            var codeLines: [String] = []
            var currentLang: String?
            var inCode = false

            func flushText() {
                let joined = textLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !joined.isEmpty {
                    segments.append(.text(joined))
                }
                textLines.removeAll()
            }

            for line in source.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("```") {
                    if inCode {
                        segments.append(.code(codeLines.joined(separator: "\n"), currentLang))
                        codeLines.removeAll()
                        currentLang = nil
                        inCode = false
                    } else {
                        flushText()
                        let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                        currentLang = lang.isEmpty ? nil : lang
                        inCode = true
                    }
                } else if inCode {
                    codeLines.append(line)
                } else {
                    textLines.append(line)
                }
            }

            if inCode {
                // Unterminated fence — recover by treating as plain text so users don't lose content.
                textLines.append(contentsOf: ["```"] + codeLines)
            }
            flushText()

            return segments.isEmpty ? [.text(source)] : segments
        }
    }
}
