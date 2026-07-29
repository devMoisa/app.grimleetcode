import SwiftUI

struct ChatcodeToggleButton: View {
    @Bindable var state: AppState
    @State private var isPulsing: Bool = false
    @State private var isHovering: Bool = false

    private let accentGradient = LinearGradient(
        colors: [.pink, .purple, .cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                state.isChatOpen.toggle()
            }
        } label: {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(accentGradient)
                .shadow(color: .pink.opacity(shadowOpacity), radius: shadowRadius)
                .shadow(color: .purple.opacity(shadowOpacity * 0.9), radius: shadowRadius * 1.4)
                .shadow(color: .cyan.opacity(shadowOpacity * 0.5), radius: shadowRadius * 0.6)
                .scaleEffect(scale)
                .padding(4)
        }
        .buttonStyle(.plain)
        .help(state.isChatOpen ? "Close Chatcode" : "Open Chatcode — AI hints & explanations")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) { isHovering = hovering }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    private var shadowOpacity: Double {
        if state.isChatOpen { return 0.9 }
        if isHovering { return 0.85 }
        return isPulsing ? 0.7 : 0.35
    }

    private var shadowRadius: CGFloat {
        if state.isChatOpen { return 10 }
        if isHovering { return 8 }
        return isPulsing ? 7 : 4
    }

    private var scale: CGFloat {
        if isHovering { return 1.08 }
        if state.isChatOpen { return 1.04 }
        return isPulsing ? 1.03 : 1.0
    }
}
