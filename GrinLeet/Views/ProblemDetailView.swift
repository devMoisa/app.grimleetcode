import SwiftUI

struct ProblemDetailView: View {
    @Bindable var state: AppState

    var body: some View {
        Group {
            if let problem = state.selectedProblem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header(problem: problem)
                        Divider()
                        Text(problem.statement)
                            .font(.body)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)

                        if !problem.examples.isEmpty {
                            SectionHeader("Examples")
                            VStack(spacing: 12) {
                                ForEach(problem.examples) { example in
                                    ExampleCard(example: example)
                                }
                            }
                        }

                        if !problem.constraints.isEmpty {
                            SectionHeader("Constraints")
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(problem.constraints, id: \.self) { constraint in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(.tertiary)
                                            .frame(width: 4, height: 4)
                                            .padding(.top, 8)
                                        Text(constraint)
                                            .font(.system(.callout, design: .monospaced))
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle(problem.title)
            } else {
                ContentUnavailableView(
                    "No problem selected",
                    systemImage: "text.magnifyingglass",
                    description: Text("Pick a problem from the list or generate a new one.")
                )
            }
        }
        .frame(minWidth: 380)
    }

    private func header(problem: Problem) -> some View {
        HStack(spacing: 8) {
            Text(problem.difficulty.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(problem.difficulty.tint.opacity(0.18), in: Capsule())
                .foregroundStyle(problem.difficulty.tint)

            ForEach(problem.tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .padding(.top, 4)
    }
}

private struct ExampleCard: View {
    let example: Problem.Example

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row(label: "Input", value: example.input)
            row(label: "Output", value: example.output)
            if let explanation = example.explanation {
                row(label: "Explanation", value: explanation, monospaced: false)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private func row(label: String, value: String, monospaced: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(monospaced ? .system(.callout, design: .monospaced) : .callout)
                .textSelection(.enabled)
        }
    }
}
