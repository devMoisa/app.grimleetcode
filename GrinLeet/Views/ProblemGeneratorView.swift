import SwiftUI

struct ProblemGeneratorView: View {
    @Bindable var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var promptText: String = ""
    @State private var difficulty: Difficulty = .medium
    @State private var topics: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?

    private let api = GrinLeetAPI.default

    private var canGenerate: Bool {
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            VStack(alignment: .leading, spacing: 6) {
                Text("Describe what you want to practice")
                    .font(.subheadline.weight(.medium))
                TextEditor(text: $promptText)
                    .font(.body)
                    .frame(minHeight: 130)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25))
                    )
                Text("e.g. \"binary tree traversal with iterative solution\" or \"sliding window problem, medium difficulty\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Difficulty")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 240)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Topics (optional, comma-separated)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("dynamic programming, graphs, hash map", text: $topics)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }

            Divider()

            HStack {
                Label {
                    Text("via ") + Text(api.baseURL.absoluteString).font(.caption.monospaced())
                } icon: {
                    Image(systemName: "network")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button {
                    generate()
                } label: {
                    if isGenerating {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Generate", systemImage: "sparkles")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!canGenerate)
            }
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 420)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.tint)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 2) {
                Text("Generate a Problem")
                    .font(.title2.weight(.semibold))
                Text("Prompt the AI to create a fresh LeetCode-style problem.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func generate() {
        isGenerating = true
        errorMessage = nil
        let capturedPrompt = promptText
        let capturedDifficulty = difficulty
        let capturedTopics = topics
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        Task { @MainActor in
            defer { isGenerating = false }
            do {
                let problem = try await api.generateProblem(
                    prompt: capturedPrompt,
                    difficulty: capturedDifficulty,
                    topics: capturedTopics
                )
                state.problems.insert(problem, at: 0)
                state.selectedProblemID = problem.id
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
