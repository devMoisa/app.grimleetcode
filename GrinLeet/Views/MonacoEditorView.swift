import SwiftUI
import WebKit

struct MonacoEditorView: NSViewRepresentable {
    @Binding var text: String
    let language: ProgrammingLanguage
    var theme: String = "dracula"
    var minimapEnabled: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let content = WKUserContentController()
        content.add(context.coordinator, name: "textChanged")
        content.add(context.coordinator, name: "ready")
        content.add(context.coordinator, name: "log")
        config.userContentController = content

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        #if DEBUG
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        #endif
        context.coordinator.webView = webView

        let url = Bundle.main.url(forResource: "monaco", withExtension: "html", subdirectory: "Monaco")
            ?? Bundle.main.url(forResource: "monaco", withExtension: "html")

        if let url {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            let fallback = """
            <html><body style="background:#282a36;color:#ff5555;font-family:sans-serif;padding:20px;">
            Monaco resources not found in bundle.
            </body></html>
            """
            webView.loadHTMLString(fallback, baseURL: nil)
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        coordinator.applyPending(
            text: text,
            language: language.monacoID,
            theme: theme,
            minimap: minimapEnabled
        )
    }

    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        fileprivate var parent: MonacoEditorView
        weak var webView: WKWebView?
        var isReady = false

        private var lastAppliedText: String?
        private var lastAppliedLanguage: String?
        private var lastAppliedTheme: String?
        private var lastAppliedMinimap: Bool?

        private var pendingText: String = ""
        private var pendingLanguage: String = ""
        private var pendingTheme: String = ""
        private var pendingMinimap: Bool = false

        init(parent: MonacoEditorView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "ready":
                isReady = true
                applyPending(
                    text: pendingText,
                    language: pendingLanguage,
                    theme: pendingTheme,
                    minimap: pendingMinimap
                )
            case "textChanged":
                guard let newText = message.body as? String else { return }
                lastAppliedText = newText
                if parent.text != newText {
                    parent.text = newText
                }
            case "log":
                if let body = message.body as? String {
                    NSLog("[Monaco] \(body)")
                }
            default:
                break
            }
        }

        nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            NSLog("[Monaco] provisional navigation failed: \(error.localizedDescription)")
        }

        nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            NSLog("[Monaco] navigation failed: \(error.localizedDescription)")
        }

        func applyPending(text: String, language: String, theme: String, minimap: Bool) {
            pendingText = text
            pendingLanguage = language
            pendingTheme = theme
            pendingMinimap = minimap

            guard let webView, isReady else { return }

            if language != lastAppliedLanguage {
                lastAppliedLanguage = language
                evaluate("window.setLanguage(\(jsString(language)));", on: webView)
            }
            if theme != lastAppliedTheme {
                lastAppliedTheme = theme
                evaluate("window.setTheme(\(jsString(theme)));", on: webView)
            }
            if minimap != lastAppliedMinimap {
                lastAppliedMinimap = minimap
                evaluate("window.setMinimapEnabled(\(minimap ? "true" : "false"));", on: webView)
            }
            if text != lastAppliedText {
                lastAppliedText = text
                evaluate("window.setText(\(jsString(text)));", on: webView)
            }
        }

        private func evaluate(_ js: String, on webView: WKWebView) {
            webView.evaluateJavaScript(js) { _, error in
                if let error {
                    #if DEBUG
                    NSLog("[Monaco] JS error: \(error.localizedDescription)")
                    #endif
                }
            }
        }

        private func jsString(_ s: String) -> String {
            guard let data = try? JSONEncoder().encode(s),
                  let json = String(data: data, encoding: .utf8) else {
                return "\"\""
            }
            return json
        }
    }
}
