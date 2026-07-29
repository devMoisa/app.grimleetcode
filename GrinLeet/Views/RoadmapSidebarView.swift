import SwiftUI

struct RoadmapSidebarView: View {
    @Bindable var state: AppState
    @State private var expandedModules: Set<Module.ID> = []

    var body: some View {
        VStack(spacing: 0) {
            trackPicker
            Divider()

            if let track = state.selectedTrack {
                trackHeader(track)
                Divider()
                moduleList(track: track)
            } else {
                ContentUnavailableView("No track selected", systemImage: "map")
                    .padding()
            }
        }
        .frame(minWidth: 280)
        .onAppear {
            if let track = state.selectedTrack {
                // Auto-expand the module containing the currently selected lesson,
                // otherwise expand the first module so the sidebar isn't empty.
                if let selected = state.selectedLessonID,
                   let mod = track.module(containing: selected)
                {
                    expandedModules.insert(mod.id)
                } else if let first = track.modules.first {
                    expandedModules.insert(first.id)
                }
            }
        }
    }

    // MARK: - Track picker

    private var trackPicker: some View {
        Menu {
            ForEach(state.tracks) { track in
                Button {
                    state.selectedTrackID = track.id
                    state.selectedLessonID = track.allLessons.first?.id
                    expandedModules.removeAll()
                    if let first = track.modules.first {
                        expandedModules.insert(first.id)
                    }
                } label: {
                    HStack {
                        Text(track.title)
                        if track.id == state.selectedTrackID {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: languageSymbol(for: state.selectedTrack?.language))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.selectedTrack?.title ?? "Pick a track")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text("\(state.selectedTrack?.modules.count ?? 0) modules · \(state.selectedTrack?.lessonCount ?? 0) lessons")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Track header (title + overall progress)

    private func trackHeader(_ track: Track) -> some View {
        let completed = track.modules
            .flatMap(\.lessons)
            .filter { state.isLessonCompleted($0) }
            .count
        let total = track.lessonCount
        let ratio = total == 0 ? 0.0 : Double(completed) / Double(total)

        return VStack(alignment: .leading, spacing: 6) {
            Text(track.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                ProgressView(value: ratio)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                Text("\(completed)/\(total)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
    }

    // MARK: - Module list

    private func moduleList(track: Track) -> some View {
        List(selection: $state.selectedLessonID) {
            ForEach(Array(track.modules.enumerated()), id: \.element.id) { index, module in
                Section {
                    if expandedModules.contains(module.id) {
                        ForEach(module.lessons) { lesson in
                            LessonRow(
                                lesson: lesson,
                                completed: state.isLessonCompleted(lesson),
                                progress: state.progress(for: lesson)
                            )
                            .tag(Optional(lesson.id))
                        }
                    }
                } header: {
                    ModuleHeader(
                        index: index + 1,
                        module: module,
                        progress: state.progress(for: module),
                        expanded: expandedModules.contains(module.id)
                    ) {
                        toggleModule(module.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func toggleModule(_ id: Module.ID) {
        withAnimation(.smooth(duration: 0.2)) {
            if expandedModules.contains(id) {
                expandedModules.remove(id)
            } else {
                expandedModules.insert(id)
            }
        }
    }

    private func languageSymbol(for lang: ProgrammingLanguage?) -> String {
        switch lang {
        case .python: "chevron.left.forwardslash.chevron.right"
        case .javascript, .typescript: "curlybraces"
        case .c: "c.circle"
        case .swift: "swift"
        case .none: "questionmark.circle"
        }
    }
}

// MARK: - Module header (clickable disclosure)

private struct ModuleHeader: View {
    let index: Int
    let module: Module
    let progress: (Int, Int)
    let expanded: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 8) {
                Image(systemName: expanded ? "chevron.down" : "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 10)
                Text("\(index).")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.tertiary)
                Text(module.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(progress.0)/\(progress.1)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .textCase(nil)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lesson row

private struct LessonRow: View {
    let lesson: Lesson
    let completed: Bool
    let progress: (Int, Int)

    var body: some View {
        HStack(spacing: 10) {
            statusIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title)
                    .font(.callout)
                    .lineLimit(1)
                if !lesson.summary.isEmpty {
                    Text(lesson.summary)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if lesson.isStub {
                Text("stub")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
            } else if progress.1 > 0 {
                Text("\(progress.0)/\(progress.1)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(completed ? .green : .secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusIcon: some View {
        Group {
            if completed {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            } else if progress.0 > 0 {
                Image(systemName: "circle.dotted").foregroundStyle(.orange)
            } else {
                Image(systemName: "circle").foregroundStyle(.tertiary)
            }
        }
        .font(.callout)
    }
}
