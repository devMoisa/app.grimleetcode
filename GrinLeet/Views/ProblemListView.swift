import SwiftUI

struct ProblemListView: View {
    @Bindable var state: AppState
    @State private var searchText: String = ""
    @State private var difficultyFilter: Difficulty?

    private var filteredProblems: [Problem] {
        state.problems.filter { problem in
            let matchesSearch = searchText.isEmpty
                || problem.title.localizedCaseInsensitiveContains(searchText)
                || problem.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            let matchesDifficulty = difficultyFilter == nil || problem.difficulty == difficultyFilter
            return matchesSearch && matchesDifficulty
        }
    }

    var body: some View {
        List(selection: $state.selectedProblemID) {
            Section {
                ForEach(filteredProblems) { problem in
                    ProblemRow(problem: problem)
                        .tag(Optional(problem.id))
                }
            } header: {
                filterBar
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search problems or tags")
        .navigationTitle("Problems")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    state.isGeneratorPresented = true
                } label: {
                    Label("Generate", systemImage: "sparkles")
                }
                .help("Generate a new problem via AI")
            }
            ToolbarItem(placement: .primaryAction) {
                ChatcodeToggleButton(state: state)
            }
        }
        .frame(minWidth: 260)
    }

    private var filterBar: some View {
        HStack(spacing: 6) {
            filterChip(nil, label: "All")
            ForEach(Difficulty.allCases) { d in
                filterChip(d, label: d.rawValue)
            }
        }
        .padding(.vertical, 4)
        .textCase(nil)
    }

    private func filterChip(_ value: Difficulty?, label: String) -> some View {
        let isSelected = difficultyFilter == value
        let tint: Color = value?.tint ?? .accentColor
        return Button {
            withAnimation(.smooth) { difficultyFilter = value }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    isSelected ? tint.opacity(0.2) : Color.secondary.opacity(0.08),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? tint : .secondary)
        }
        .buttonStyle(.plain)
    }
}

private struct ProblemRow: View {
    let problem: Problem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(problem.title)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(problem.difficulty.rawValue)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(problem.difficulty.tint.opacity(0.18), in: Capsule())
                    .foregroundStyle(problem.difficulty.tint)
                ForEach(problem.tags.prefix(2), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if problem.tags.count > 2 {
                    Text("+\(problem.tags.count - 2)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
