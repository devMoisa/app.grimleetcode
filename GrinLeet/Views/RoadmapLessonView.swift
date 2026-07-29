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
        Button {
            state.selectExercise(exercise, in: lesson)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    completionIcon
                    Text("Exercise \(index) · \(exercise.title)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if isSelected {
                        Label("Open in editor", systemImage: "arrow.right.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.tint)
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                    }
                }
                Text(exercise.statement)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
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
        }
        .buttonStyle(.plain)
    }

    private var completionIcon: some View {
        Image(systemName: isCompleted ? "checkmark.seal.fill" : "seal")
            .foregroundStyle(isCompleted ? .green : .secondary)
            .font(.headline)
    }
}
