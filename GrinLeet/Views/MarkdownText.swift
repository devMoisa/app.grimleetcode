import SwiftUI

/// Renders GitHub-style Markdown as native SwiftUI views. Supports:
/// - Paragraphs (inline bold, italic, links, highlighted inline `code`)
/// - Headings (# through ######)
/// - Fenced code blocks (```lang\n...\n```) with a Dracula-toned box
/// - Bulleted lists (`- ` / `* `)
/// - Ordered lists (`1. `)
/// - Tables (`| a | b |\n|---|---|`)
/// - Horizontal rules (`---`, `***`, `___`)
///
/// Written by hand — no Swift Package dependency. Not a full CommonMark parser,
/// but covers what lesson theory and chat responses actually use.
struct MarkdownText: View {
    let source: String
    var textColor: Color = .primary
    var baseFont: Font = .body

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
                    list(items, ordered: false)
                case .ordered(let items):
                    list(items, ordered: true)
                case .table(let headers, let rows):
                    table(headers: headers, rows: rows)
                case .rule:
                    Divider().padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Paragraph

    private func paragraph(_ md: String) -> some View {
        Text(styledInline(md))
            .font(baseFont)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Parses inline Markdown; overlays a monospaced/highlighted style on inline code.
    /// The base font is intentionally NOT baked in so callers can pick per context.
    private func styledInline(_ md: String) -> AttributedString {
        guard var attributed = try? AttributedString(
            markdown: md,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) else {
            var plain = AttributedString(md)
            plain.foregroundColor = textColor
            return plain
        }

        for run in attributed.runs {
            if run.inlinePresentationIntent?.contains(.code) == true {
                attributed[run.range].font = .system(.callout, design: .monospaced)
                attributed[run.range].backgroundColor = codeInlineBackground
                attributed[run.range].foregroundColor = codeInlineForeground
            }
        }
        attributed.foregroundColor = textColor
        return attributed
    }

    // MARK: - Heading

    private func heading(level: Int, text: String) -> some View {
        let font: Font = switch level {
        case 1: .title.weight(.bold)
        case 2: .title2.weight(.semibold)
        case 3: .title3.weight(.semibold)
        default: .headline
        }
        return Text(styledInline(text))
            .font(font)
            .padding(.top, level <= 2 ? 6 : 2)
    }

    // MARK: - Lists

    private func list(_ items: [String], ordered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items.indices, id: \.self) { i in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(ordered ? "\(i + 1)." : "•")
                        .font(baseFont.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 18, alignment: .trailing)
                    Text(styledInline(items[i]))
                        .font(baseFont)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Code block

    private func codeBlock(_ code: String, language: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(language?.isEmpty == false ? language! : "code")
                    .font(.caption2.weight(.semibold).monospaced())
                    .foregroundStyle(codeChromeForeground)
                Spacer()
                CodeCopyButton(text: code, chromeForeground: codeChromeForeground)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(codeChromeBackground)

            Text(code)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(codeForeground)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(codeBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.06))
        )
    }

    // MARK: - Table

    private func table(headers: [String], rows: [[String]]) -> some View {
        let cols = max(headers.count, rows.map(\.count).max() ?? 0)
        return VStack(spacing: 0) {
            // Header row
            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<cols, id: \.self) { c in
                    Text(styledInline(c < headers.count ? headers[c] : ""))
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                    if c < cols - 1 {
                        Rectangle()
                            .fill(tableBorder)
                            .frame(width: 1)
                    }
                }
            }
            .background(tableHeaderBackground)

            Rectangle().fill(tableBorder).frame(height: 1)

            // Body rows
            ForEach(rows.indices, id: \.self) { r in
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<cols, id: \.self) { c in
                        Text(styledInline(c < rows[r].count ? rows[r][c] : ""))
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        if c < cols - 1 {
                            Rectangle()
                                .fill(tableBorder)
                                .frame(width: 1)
                        }
                    }
                }
                .background(r.isMultiple(of: 2) ? tableRowBackground : Color.clear)
                if r < rows.count - 1 {
                    Rectangle().fill(tableBorder).frame(height: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tableBorder)
        )
    }

    // MARK: - Colors (Dracula-toned)

    private var codeBackground: Color { Color(red: 40/255, green: 42/255, blue: 54/255) }
    private var codeForeground: Color { Color(red: 248/255, green: 248/255, blue: 242/255) }
    private var codeChromeBackground: Color { Color(red: 33/255, green: 34/255, blue: 44/255) }
    private var codeChromeForeground: Color { Color(red: 189/255, green: 147/255, blue: 249/255) }
    private var codeInlineBackground: Color { Color(red: 68/255, green: 71/255, blue: 90/255, opacity: 0.55) }
    private var codeInlineForeground: Color { Color(red: 241/255, green: 250/255, blue: 140/255) }
    private var tableBorder: Color { Color.secondary.opacity(0.25) }
    private var tableHeaderBackground: Color { Color.secondary.opacity(0.12) }
    private var tableRowBackground: Color { Color.secondary.opacity(0.05) }

    // MARK: - Copy button (used in code block chrome)

    private struct CodeCopyButton: View {
        let text: String
        let chromeForeground: Color
        @State private var justCopied: Bool = false

        var body: some View {
            Button(action: copy) {
                HStack(spacing: 4) {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption2)
                    Text(justCopied ? "Copied" : "Copy")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(justCopied ? Color.green : chromeForeground.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Color.white.opacity(justCopied ? 0 : 0.08),
                    in: RoundedRectangle(cornerRadius: 4)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Copy to clipboard")
        }

        private func copy() {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(text, forType: .string)
            withAnimation(.easeInOut(duration: 0.15)) { justCopied = true }
            Task {
                try? await Task.sleep(for: .milliseconds(1400))
                withAnimation(.easeInOut(duration: 0.2)) { justCopied = false }
            }
        }
    }

    // MARK: - Block parser

    enum Block: Hashable {
        case paragraph(String)
        case heading(level: Int, text: String)
        case code(String, String?)
        case bullet([String])
        case ordered([String])
        case table(headers: [String], rows: [[String]])
        case rule

        static func parse(_ source: String) -> [Block] {
            var blocks: [Block] = []
            var paragraphBuffer: [String] = []
            var bulletBuffer: [String] = []
            var orderedBuffer: [String] = []
            var codeBuffer: [String] = []
            var currentLang: String?
            var inCode = false

            let lines = source.components(separatedBy: "\n")

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
            func flushOrdered() {
                if !orderedBuffer.isEmpty {
                    blocks.append(.ordered(orderedBuffer))
                    orderedBuffer.removeAll()
                }
            }
            func flushLists() { flushBullets(); flushOrdered() }

            var i = 0
            while i < lines.count {
                let rawLine = lines[i]
                let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

                // Fence
                if trimmed.hasPrefix("```") {
                    if inCode {
                        blocks.append(.code(codeBuffer.joined(separator: "\n"), currentLang))
                        codeBuffer.removeAll()
                        currentLang = nil
                        inCode = false
                    } else {
                        flushParagraph()
                        flushLists()
                        let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                        currentLang = lang.isEmpty ? nil : lang
                        inCode = true
                    }
                    i += 1
                    continue
                }
                if inCode {
                    codeBuffer.append(rawLine)
                    i += 1
                    continue
                }

                // Table: current is |cells|, next line is separator (----|----)
                if trimmed.hasPrefix("|"), trimmed.hasSuffix("|"), i + 1 < lines.count {
                    let nextTrimmed = lines[i + 1].trimmingCharacters(in: .whitespaces)
                    if isTableSeparator(nextTrimmed) {
                        flushParagraph()
                        flushLists()
                        let headers = parseTableRow(trimmed)
                        var rows: [[String]] = []
                        var j = i + 2
                        while j < lines.count {
                            let bodyTrimmed = lines[j].trimmingCharacters(in: .whitespaces)
                            if bodyTrimmed.hasPrefix("|"), bodyTrimmed.hasSuffix("|") {
                                rows.append(parseTableRow(bodyTrimmed))
                                j += 1
                            } else {
                                break
                            }
                        }
                        blocks.append(.table(headers: headers, rows: rows))
                        i = j
                        continue
                    }
                }

                // Horizontal rule
                if isHorizontalRule(trimmed) {
                    flushParagraph()
                    flushLists()
                    blocks.append(.rule)
                    i += 1
                    continue
                }

                // Heading
                if trimmed.hasPrefix("#") {
                    let hashCount = trimmed.prefix(while: { $0 == "#" }).count
                    if hashCount >= 1, hashCount <= 6 {
                        let after = trimmed.dropFirst(hashCount)
                        if after.hasPrefix(" ") {
                            flushParagraph()
                            flushLists()
                            let text = String(after.dropFirst()).trimmingCharacters(in: .whitespaces)
                            blocks.append(.heading(level: hashCount, text: text))
                            i += 1
                            continue
                        }
                    }
                }

                // Bulleted list
                if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                    flushParagraph()
                    flushOrdered()
                    bulletBuffer.append(String(trimmed.dropFirst(2)))
                    i += 1
                    continue
                }

                // Ordered list: "1. " / "12. " etc.
                if let dotIdx = trimmed.firstIndex(of: "."),
                   let space = trimmed[trimmed.index(after: dotIdx)...].first,
                   space == " ",
                   trimmed[..<dotIdx].allSatisfy(\.isNumber),
                   !trimmed[..<dotIdx].isEmpty
                {
                    flushParagraph()
                    flushBullets()
                    let content = trimmed[trimmed.index(dotIdx, offsetBy: 2)...]
                    orderedBuffer.append(String(content))
                    i += 1
                    continue
                }

                // A non-list line ends any active list
                flushLists()

                if trimmed.isEmpty {
                    flushParagraph()
                } else {
                    paragraphBuffer.append(rawLine)
                }
                i += 1
            }

            if inCode {
                // Unterminated fence — recover as raw text so nothing is lost
                paragraphBuffer.append("```" + (currentLang ?? ""))
                paragraphBuffer.append(contentsOf: codeBuffer)
            }
            flushParagraph()
            flushLists()

            return blocks.isEmpty ? [.paragraph(source)] : blocks
        }

        // MARK: - Helpers

        private static func isTableSeparator(_ line: String) -> Bool {
            guard line.hasPrefix("|"), line.hasSuffix("|") else { return false }
            let cells = parseTableRow(line)
            guard !cells.isEmpty else { return false }
            for cell in cells {
                let stripped = cell.replacingOccurrences(of: " ", with: "")
                if stripped.isEmpty { return false }
                for ch in stripped {
                    if ch != "-" && ch != ":" { return false }
                }
            }
            return true
        }

        private static func parseTableRow(_ line: String) -> [String] {
            var content = line
            if content.hasPrefix("|") { content = String(content.dropFirst()) }
            if content.hasSuffix("|") { content = String(content.dropLast()) }
            return content.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        private static func isHorizontalRule(_ line: String) -> Bool {
            guard line.count >= 3 else { return false }
            let allowed: Set<Character> = ["-", "*", "_"]
            guard let first = line.first, allowed.contains(first) else { return false }
            let stripped = line.replacingOccurrences(of: " ", with: "")
            return stripped.count >= 3 && stripped.allSatisfy { $0 == first }
        }
    }
}
