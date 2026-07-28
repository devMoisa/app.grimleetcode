import SwiftUI

struct CodeWorkspaceView: View {
    @Bindable var state: AppState

    var body: some View {
        VSplitView {
            editorSection
                .frame(minHeight: 260)
            resultsSection
                .frame(minHeight: 140)
        }
        .navigationTitle("Workspace")
        .frame(minWidth: 460)
    }

    // MARK: - Editor

    private var editorSection: some View {
        VStack(spacing: 0) {
            editorToolbar
            Divider()
            CodeEditorPlaceholder(text: $state.currentCode, language: state.selectedLanguage)
        }
    }

    private var editorToolbar: some View {
        HStack(spacing: 8) {
            Picker("Language", selection: $state.selectedLanguage) {
                ForEach(ProgrammingLanguage.allCases) { lang in
                    Text(lang.rawValue).tag(lang)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: 160)
            .onChange(of: state.selectedLanguage) { _, _ in
                state.resetCodeToStarter()
            }
            .onChange(of: state.selectedProblemID) { _, _ in
                state.resetCodeToStarter()
            }

            Spacer()

            Button {
                state.resetCodeToStarter()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help("Reset to starter code")

            Button {
                Task { await state.runCurrentCode() }
            } label: {
                if state.isRunning {
                    ProgressView().controlSize(.small)
                } else {
                    Label("Run", systemImage: "play.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.isRunning || state.selectedProblem == nil)
            .keyboardShortcut("r", modifiers: .command)

            Button {
                Task { await state.submitCurrentCode() }
            } label: {
                Label("Submit", systemImage: "checkmark.seal.fill")
            }
            .buttonStyle(.bordered)
            .disabled(state.isRunning || state.selectedProblem == nil)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(10)
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Results", systemImage: "terminal")
                    .font(.headline)
                Spacer()
                if let result = state.lastResult {
                    StatusBadge(status: result.status)
                }
            }
            .padding(10)
            Divider()
            ScrollView {
                if let result = state.lastResult {
                    resultDetail(result)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ContentUnavailableView(
                        "No output yet",
                        systemImage: "terminal",
                        description: Text("Run or submit your code to see results here.")
                    )
                    .padding(.vertical, 24)
                }
            }
        }
    }

    @ViewBuilder
    private func resultDetail(_ result: ExecutionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let verdict = result.verdict {
                Text(verdict)
                    .font(.callout)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            if !result.stdout.isEmpty {
                outputBlock(title: "stdout", body: result.stdout, tint: .primary)
            }
            if !result.stderr.isEmpty {
                outputBlock(title: "stderr", body: result.stderr, tint: .red)
            }
            if let ms = result.executionTimeMs {
                Text("Ran in \(ms) ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func outputBlock(title: String, body: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(body)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(tint)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

private struct StatusBadge: View {
    let status: ExecutionResult.Status

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch status {
        case .success: "Passed"
        case .failed: "Failed"
        case .running: "Running"
        case .error: "Error"
        }
    }

    private var color: Color {
        switch status {
        case .success: .green
        case .failed: .red
        case .running: .orange
        case .error: .red
        }
    }
}
