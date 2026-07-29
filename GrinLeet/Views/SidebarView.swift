import SwiftUI

struct SidebarView: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            modeSwitcher
            Divider()
            Group {
                switch state.mode {
                case .problems:
                    ProblemListView(state: state)
                case .roadmap:
                    RoadmapSidebarView(state: state)
                }
            }
        }
        .frame(minWidth: 280)
    }

    private var modeSwitcher: some View {
        Picker("Mode", selection: $state.mode) {
            ForEach(AppMode.allCases) { mode in
                Label(mode.label, systemImage: mode.systemImage)
                    .tag(mode)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}
