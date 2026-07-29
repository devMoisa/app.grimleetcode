import SwiftUI

struct ChatPanelView: View {
    @Bindable var state: AppState
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [.pink, .purple, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messagesList
            Divider()
            inputBar
        }
        .background(.regularMaterial)
        .frame(width: 360)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accentGradient.opacity(0.6))
                .frame(width: 1)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.title3)
                .foregroundStyle(accentGradient)
                .shadow(color: .purple.opacity(0.6), radius: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text("Chatcode")
                    .font(.headline)
                Text(state.selectedProblem?.title ?? "No problem selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    state.clearChatForCurrentProblem()
                } label: {
                    Label("Clear conversation", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    state.isChatOpen = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close chat")
        }
        .padding(12)
    }

    // MARK: - Messages

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if state.currentChatMessages.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    } else {
                        ForEach(state.currentChatMessages) { message in
                            MessageBubble(message: message, accent: accentGradient)
                                .id(message.id)
                        }
                    }
                    if state.isChatSending {
                        TypingIndicator(accent: accentGradient)
                            .id("typing")
                    }
                    if let err = state.chatError {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(12)
            }
            .onChange(of: state.currentChatMessages.count) { _, _ in
                withAnimation(.smooth) {
                    if state.isChatSending {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let last = state.currentChatMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: state.isChatSending) { _, sending in
                if sending {
                    withAnimation(.smooth) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(accentGradient)
                .shadow(color: .purple.opacity(0.5), radius: 12)
            Text("Ask Chatcode anything")
                .font(.headline)
            Text("Get hints, explanations, and reviews without spoiling the solution.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            promptChips
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var promptChips: some View {
        VStack(spacing: 6) {
            promptChip("Por onde começo?")
            promptChip("Qual a complexidade ótima?")
            promptChip("Revise meu código no editor")
        }
    }

    private func promptChip(_ text: String) -> some View {
        Button {
            draft = text
            inputFocused = true
        } label: {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message Chatcode…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.25))
                )
                .focused($inputFocused)
                .onSubmit { send() }

            Button {
                send()
            } label: {
                Image(systemName: state.isChatSending ? "hourglass" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? AnyShapeStyle(accentGradient) : AnyShapeStyle(Color.secondary))
                    .shadow(color: canSend ? .purple.opacity(0.5) : .clear, radius: canSend ? 6 : 0)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(12)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !state.isChatSending
            && state.selectedProblem != nil
    }

    private func send() {
        guard canSend else { return }
        let text = draft
        draft = ""
        Task { await state.sendChatMessage(text) }
    }
}

// MARK: - Message bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let accent: LinearGradient

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 32)
                bubble
            } else {
                assistantAvatar
                bubble
                Spacer(minLength: 32)
            }
        }
    }

    private var assistantAvatar: some View {
        Image(systemName: "sparkles")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(6)
            .background(accent, in: Circle())
            .shadow(color: .purple.opacity(0.4), radius: 4)
    }

    @ViewBuilder
    private var bubble: some View {
        let isUser = message.role == .user
        Text(message.content)
            .font(.callout)
            .textSelection(.enabled)
            .foregroundStyle(isUser ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isUser
                    ? AnyShapeStyle(accent)
                    : AnyShapeStyle(Color.secondary.opacity(0.12)),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .shadow(color: isUser ? .purple.opacity(0.25) : .clear, radius: 6)
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

// MARK: - Typing indicator

private struct TypingIndicator: View {
    let accent: LinearGradient
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(6)
                .background(accent, in: Circle())

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 6, height: 6)
                        .opacity(dotOpacity(i))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    private func dotOpacity(_ i: Int) -> Double {
        let shifted = (phase + CGFloat(i) * 0.33).truncatingRemainder(dividingBy: 1)
        let wave = 1 - Double(abs(0.5 - shifted)) * 2
        return 0.3 + 0.7 * wave
    }
}
