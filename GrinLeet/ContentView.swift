//
//  ContentView.swift
//  GrinLeet
//
//  Created by Moises Vilas Boas on 28/07/26.
//

import SwiftUI

struct ContentView: View {
    @State private var state = AppState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        HStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                ProblemListView(state: state)
            } content: {
                ProblemDetailView(state: state)
            } detail: {
                CodeWorkspaceView(state: state)
            }
            .navigationSplitViewStyle(.balanced)

            if state.isChatOpen {
                ChatPanelView(state: state)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $state.isGeneratorPresented) {
            ProblemGeneratorView(state: state)
        }
        .frame(minWidth: 1100, minHeight: 700)
    }
}

#Preview {
    ContentView()
}
