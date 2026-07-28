import SwiftUI

struct ProblemGeneratorView: View {
    @Bindable var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var promptText: String = ""
    @State private var difficulty: Difficulty = .medium
    @State private var topics: String = ""
    @State private var isGenerating: Bool = false

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

            Divider()

            HStack {
                Label("OpenRouter · not wired to backend yet", systemImage: "network")
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
        let capturedPrompt = promptText
        let capturedDifficulty = difficulty
        let capturedTopics = topics
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            let mocked = Problem(
                id: UUID(),
                title: "Generated: \(capturedPrompt.prefix(48))",
                difficulty: capturedDifficulty,
                tags: capturedTopics.isEmpty ? ["Generated"] : capturedTopics,
                statement: """
                _This is a mock problem generated from your prompt:_

                > \(capturedPrompt)

                Wire this sheet to your FastAPI + OpenRouter endpoint to produce a real problem \
                statement, examples, and constraints.
                """,
                examples: [
                    .init(input: "example input", output: "example output", explanation: "placeholder")
                ],
                constraints: [],
                createdAt: Date()
            )
            state.problems.insert(mocked, at: 0)
            state.selectedProblemID = mocked.id
            isGenerating = false
            dismiss()
        }
    }
}
