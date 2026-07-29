import SwiftUI

struct RoadmapLessonView: View {
    @Bindable var state: AppState

    var body: some View {
        Group {
            if let lesson = state.selectedLesson {
                LessonContent(state: state, lesson: lesson)
            } else {
                ContentUnavailableView(
                    "Pick a lesson",
                    systemImage: "book.pages",
                    description: Text("Choose a lesson from the sidebar to see its theory and exercises.")
                )
            }
        }
        .frame(minWidth: 400)
    }
}

private struct LessonContent: View {
    @Bindable var state: AppState
    let lesson: Lesson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if lesson.isStub {
                    stubBanner
                } else {
                    theorySection
                }

                if !lesson.exercises.isEmpty {
                    exercisesSection
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(lesson.title)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lesson.title)
                .font(.largeTitle.weight(.semibold))
            if !lesson.summary.isEmpty {
                Text(lesson.summary)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            let progress = state.progress(for: lesson)
            if progress.1 > 0 {
                HStack(spacing: 6) {
                    Image(systemName: state.isLessonCompleted(lesson) ? "checkmark.seal.fill" : "circle.dotted")
                        .foregroundStyle(state.isLessonCompleted(lesson) ? .green : .orange)
                    Text("\(progress.0) of \(progress.1) exercises solved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Theory

    private var theorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            MarkdownText(source: lesson.theory)
        }
    }

    // MARK: - Stub banner (content-to-be-generated)

    private var stubBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.tint)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Content not generated yet")
                    .font(.headline)
                Text("Only the outline exists so far. Phase 2 will wire this up to POST /lesson/generate so you can ask the AI to produce the theory and exercises for this lesson on demand.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("Exercises")
                .font(.title2.weight(.semibold))

            ForEach(Array(lesson.exercises.enumerated()), id: \.element.id) { idx, exercise in
                ExerciseCard(
                    state: state,
                    lesson: lesson,
                    exercise: exercise,
                    index: idx + 1
                )
            }
        }
    }
}

private struct ExerciseCard: View {
    @Bindable var state: AppState
    let lesson: Lesson
    let exercise: Problem
    let index: Int

    private var isSelected: Bool { state.selectedProblemID == exercise.id }
    private var isCompleted: Bool {
        state.isExerciseCompleted(lessonID: lesson.id, exerciseID: exercise.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            MarkdownText(source: exercise.statement)
            if !exercise.examples.isEmpty {
                examplesSection
            }
            if !exercise.constraints.isEmpty {
                constraintsSection
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.secondary.opacity(isSelected ? 0.15 : 0.07),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? Color.accentColor : Color.clear,
                    lineWidth: 1.5
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            state.selectExercise(exercise, in: lesson)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            completionIcon
            Text("Exercise \(index) · \(exercise.title)")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()

            askChatcodeButton

            if isSelected {
                Label("Open in editor", systemImage: "arrow.right.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.tint)
                    .font(.title3)
            } else {
                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
        }
    }

    private var askChatcodeButton: some View {
        Button {
            state.selectExercise(exercise, in: lesson)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                state.isChatOpen = true
            }
        } label: {
            Image(systemName: "questionmark.bubble.fill")
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.5), radius: 4)
        }
        .buttonStyle(.plain)
        .help("Ask Chatcode to explain this exercise")
    }

    private var completionIcon: some View {
        Image(systemName: isCompleted ? "checkmark.seal.fill" : "seal")
            .foregroundStyle(isCompleted ? .green : .secondary)
            .font(.headline)
    }

    // MARK: - Examples

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text("Examples")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(exercise.examples) { example in
                ExampleBlock(example: example)
            }
        }
    }

    // MARK: - Constraints

    private var constraintsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text("Constraints")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(exercise.constraints, id: \.self) { c in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(.tertiary)
                        .frame(width: 4, height: 4)
                        .padding(.top, 8)
                    Text(c)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }
}

private struct ExampleBlock: View {
    let example: Problem.Example

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("Input", value: example.input)
            row("Output", value: example.output)
            if let explanation = example.explanation, !explanation.isEmpty {
                row("Explanation", value: explanation, monospaced: false)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }

    private func row(_ label: String, value: String, monospaced: Bool = true) -> some View {
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
