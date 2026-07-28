import SwiftUI

/// Placeholder editor — will be replaced by Monaco-in-WKWebView.
/// Kept isolated so the swap is a one-file change.
struct CodeEditorPlaceholder: View {
    @Binding var text: String
    let language: ProgrammingLanguage

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .padding(.horizontal, 4)

            hint
                .padding(8)
        }
    }

    private var hint: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
            Text("Monaco editor coming soon · \(language.rawValue)")
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial, in: Capsule())
        .foregroundStyle(.secondary)
        .allowsHitTesting(false)
    }
}
