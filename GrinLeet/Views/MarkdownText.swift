import SwiftUI

/// Renders GitHub-style Markdown as native SwiftUI views. Supports:
/// - Paragraphs (with inline bold, italic, links, and highlighted inline `code`)
/// - Headings (# through ######)
/// - Fenced code blocks (```lang\n...\n```) with a Dracula-toned box
/// - Bulleted lists (`- ` or `* `)
///
/// Written from scratch instead of adding a Swift Package dependency — good enough
/// for lesson theory and chat responses; tables and images are not (yet) supported.
struct MarkdownText: View {
    let source: String
    var textColor: Color = .primary

    private var blocks: [Block] { Block.parse(source) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(blocks.indices, id: \.self) { i in
                switch blocks[i] {
                case .paragraph(let str):
                    paragraph(str)
                case .heading(let level, let text):
                    heading(level: level, text: text)
                case .code(let code, let lang):
                    codeBlock(code, language: lang)
                case .bullet(let items):
                    bulletList(items)
                }
            }
        }
    }

    // MARK: - Paragraphs

    @ViewBuilder
    private func paragraph(_ md: String) -> some View {
        Text(styled(md))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Parses inline Markdown and styles inline `code` runs with monospaced font +
    /// a subtle highlight so they visually pop out.
    private func styled(_ md: String) -> AttributedString {
        guard var attributed = try? AttributedString(
            markdown: md,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) else {
            return AttributedString(md)
        }

        for run in attributed.runs {
            if run.inlinePresentationIntent?.contains(.code) == true {
                attributed[run.range].font = .system(.callout, design: .monospaced)
                attributed[run.range].backgroundColor = codeInlineBackground
                attributed[run.range].foregroundColor = codeInlineForeground
            }
        }

        // Base attributes for the whole paragraph.
        attributed.foregroundColor = textColor
        attributed.font = .body

        return attributed
    }

    // MARK: - Headings

    @ViewBuilder
    private func heading(level: Int, text: String) -> some View {
        let font: Font = switch level {
        case 1: .title.weight(.bold)
        case 2: .title2.weight(.semibold)
        case 3: .title3.weight(.semibold)
        default: .headline
        }
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .padding(.top, level <= 2 ? 6 : 2)
    }

    // MARK: - Bullets

    @ViewBuilder
    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items.indices, id: \.self) { i in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(styled(items[i]))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Code block

    private func codeBlock(_ code: String, language: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                HStack {
                    Text(language)
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(codeChromeForeground)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(codeChromeBackground, in: UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: 8, topTrailing: 8), style: .continuous
                ))
            }
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(codeForeground)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    codeBackground,
                    in: UnevenRoundedRectangle(
                        cornerRadii: language?.isEmpty == false
                            ? .init(bottomLeading: 8, bottomTrailing: 8)
                            : .init(topLeading: 8, bottomLeading: 8, bottomTrailing: 8, topTrailing: 8),
                        style: .continuous
                    )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.06))
        )
    }

    // MARK: - Colors (Dracula-toned so code blocks feel consistent with the Monaco editor)

    private var codeBackground: Color { Color(red: 40/255, green: 42/255, blue: 54/255) }
    private var codeForeground: Color { Color(red: 248/255, green: 248/255, blue: 242/255) }
    private var codeChromeBackground: Color { Color(red: 33/255, green: 34/255, blue: 44/255) }
    private var codeChromeForeground: Color { Color(red: 189/255, green: 147/255, blue: 249/255) }
    private var codeInlineBackground: Color { Color(red: 68/255, green: 71/255, blue: 90/255, opacity: 0.45) }
    private var codeInlineForeground: Color { Color(red: 241/255, green: 250/255, blue: 140/255) }

    // MARK: - Segmentation

    enum Block: Hashable {
        case paragraph(String)
        case heading(level: Int, text: String)
        case code(String, String?)
        case bullet([String])

        static func parse(_ source: String) -> [Block] {
            var blocks: [Block] = []
            var paragraphBuffer: [String] = []
            var bulletBuffer: [String] = []
            var codeBuffer: [String] = []
            var currentLang: String?
            var inCode = false

            func flushParagraph() {
                let joined = paragraphBuffer.joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !joined.isEmpty {
                    blocks.append(.paragraph(joined))
                }
                paragraphBuffer.removeAll()
            }

            func flushBullets() {
                if !bulletBuffer.isEmpty {
                    blocks.append(.bullet(bulletBuffer))
                    bulletBuffer.removeAll()
                }
            }

            for rawLine in source.components(separatedBy: "\n") {
                let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

                // Fence toggle
                if trimmed.hasPrefix("```") {
                    if inCode {
                        blocks.append(.code(codeBuffer.joined(separator: "\n"), currentLang))
                        codeBuffer.removeAll()
                        currentLang = nil
                        inCode = false
                    } else {
                        flushParagraph()
                        flushBullets()
                        let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                        currentLang = lang.isEmpty ? nil : lang
                        inCode = true
                    }
                    continue
                }
                if inCode {
                    codeBuffer.append(rawLine)
                    continue
                }

                // Heading (# through ######)
                if trimmed.hasPrefix("#") {
                    let hashPrefix = trimmed.prefix(while: { $0 == "#" })
                    let level = hashPrefix.count
                    if level >= 1, level <= 6 {
                        let after = trimmed.dropFirst(level)
                        if after.hasPrefix(" ") {
                            flushParagraph()
                            flushBullets()
                            let text = String(after.dropFirst()).trimmingCharacters(in: .whitespaces)
                            blocks.append(.heading(level: level, text: text))
                            continue
                        }
                    }
                }

                // Bullet (- or *)
                if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                    flushParagraph()
                    bulletBuffer.append(String(trimmed.dropFirst(2)))
                    continue
                }

                // Non-bullet line ends bullet run
                flushBullets()

                if trimmed.isEmpty {
                    // Blank line separates paragraphs
                    flushParagraph()
                } else {
                    paragraphBuffer.append(rawLine)
                }
            }

            // Recovery: unterminated fence — dump raw text so nothing is lost
            if inCode {
                paragraphBuffer.append("```" + (currentLang ?? ""))
                paragraphBuffer.append(contentsOf: codeBuffer)
            }
            flushParagraph()
            flushBullets()

            return blocks.isEmpty ? [.paragraph(source)] : blocks
        }
    }
}
