import SwiftUI

/// Einbürgerungstest practice quiz (P6-R3): work through a round of "Leben in
/// Deutschland" questions one at a time — German prompt + English translation +
/// 4 tappable options — with immediate correct/incorrect feedback, then a result
/// card (score, pass/fail, required-to-pass) and a restart button.
///
/// **Session-only by design:** progress lives in `@State` and is deliberately
/// NOT persisted (it is practice, not a record). All scoring is in the pure
/// `EinbuergerungstestEngine`; this screen is presentation + input. Carries the
/// RDG note — practice only, not the official exam.
struct EinbuergerungstestView: View {

    /// The questions for this round (deterministic order from the engine).
    private let questions: [EinbuergerungstestQuestion]

    /// Index of the question currently shown.
    @State private var current: Int
    /// questionId → chosen option index, for the questions already answered.
    @State private var answers: [Int: Int]
    /// Whether the user has reached the results card.
    @State private var finished: Bool

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    init(
        questions: [EinbuergerungstestQuestion]? = nil,
        current: Int = 0,
        answers: [Int: Int] = [:],
        finished: Bool = false,
        embedInScrollView: Bool = true
    ) {
        self.questions = questions ?? EinbuergerungstestEngine.round(from: EinbuergerungstestBank.questions)
        self._current = State(initialValue: current)
        self._answers = State(initialValue: answers)
        self._finished = State(initialValue: finished)
        self.embedInScrollView = embedInScrollView
    }

    private var result: EinbuergerungstestResult {
        EinbuergerungstestEngine.score(questions: questions, answers: answers)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_einbuergerungstest_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_einbtest_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            if finished || questions.isEmpty {
                resultCard
            } else {
                questionSection
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Question

    @ViewBuilder
    private var questionSection: some View {
        let question = questions[current]
        let chosen = answers[question.id]
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(progressLine)
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)

            Text(question.prompt.de)
                .appText(.cardTitle)
                .foregroundStyle(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(question.prompt.en)
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    optionRow(
                        option: option,
                        index: index,
                        answer: question.answerIndex,
                        chosen: chosen)
                }
            }

            if let chosen {
                feedbackLine(isCorrect: chosen == question.answerIndex)
                Button(action: advance) {
                    Text(isLast ? "tool_einbtest_see_result" : "tool_einbtest_next")
                        .appText(.bodyEmphasis)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.md)
                        .background(AppColor.primary, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var isLast: Bool { current >= questions.count - 1 }

    private var progressLine: String {
        String(
            format: String(localized: "tool_einbtest_progress_fmt"),
            current + 1, questions.count)
    }

    private func optionRow(
        option: BilingualText, index: Int, answer: Int, chosen: Int?
    ) -> some View {
        let isChosen = chosen == index
        let revealed = chosen != nil
        let isCorrectOption = index == answer
        // After answering, highlight the correct option green and a wrong pick red.
        let tint: Color = {
            guard revealed else { return AppColor.line }
            if isCorrectOption { return AppColor.primary }
            if isChosen { return AppColor.severityUrgent }
            return AppColor.line
        }()
        let icon: String? = {
            guard revealed else { return nil }
            if isCorrectOption { return "checkmark.circle.fill" }
            if isChosen { return "xmark.circle.fill" }
            return nil
        }()
        return Button {
            if chosen == nil { answers[questions[current].id] = index }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(option.de)
                        .appText(.body)
                        .foregroundStyle(AppColor.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(option.en)
                        .appText(.caption)
                        .foregroundStyle(AppColor.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let icon {
                    Image(systemName: icon).foregroundStyle(tint)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(AppSpacing.md)
            .background(
                (revealed && isCorrectOption ? AppColor.primaryWash : AppColor.card),
                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(tint.opacity(revealed ? 0.6 : 1), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(revealed)
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : .isButton)
    }

    private func feedbackLine(isCorrect: Bool) -> some View {
        Label(
            isCorrect ? "tool_einbtest_correct" : "tool_einbtest_incorrect",
            systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            .appText(.label)
            .foregroundStyle(isCorrect ? AppColor.primary : AppColor.severityUrgent)
    }

    private func advance() {
        if isLast {
            finished = true
        } else {
            current += 1
        }
    }

    // MARK: - Result

    private var resultCard: some View {
        let r = result
        let tint = r.passed ? AppColor.primary : AppColor.severityUrgent
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(r.passed ? "tool_einbtest_passed" : "tool_einbtest_not_passed")
                .appText(.cardTitle)
                .foregroundStyle(tint)
            Text(scoreLine(r))
                .appText(.bodyEmphasis)
                .foregroundStyle(AppColor.ink)
            Text(requiredLine(r))
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: restart) {
                Label("tool_einbtest_restart", systemImage: "arrow.clockwise")
                    .appText(.bodyEmphasis)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(AppColor.primary, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 1))
    }

    private func scoreLine(_ r: EinbuergerungstestResult) -> String {
        String(format: String(localized: "tool_einbtest_score_fmt"), r.correct, r.total)
    }

    private func requiredLine(_ r: EinbuergerungstestResult) -> String {
        String(format: String(localized: "tool_einbtest_required_fmt"), r.requiredCorrect)
    }

    private func restart() {
        answers = [:]
        current = 0
        finished = false
    }
}

#Preview {
    NavigationStack { EinbuergerungstestView() }
        .appFontDesign()
}
