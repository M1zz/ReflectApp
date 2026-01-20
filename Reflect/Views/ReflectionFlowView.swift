import SwiftUI
import SwiftData

// MARK: - 회고 플로우 뷰
struct ReflectionFlowView: View {
    @Bindable var goal: Goal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 단계 인디케이터
                stageIndicator
                    .padding()

                Divider()

                // 현재 단계 콘텐츠
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch goal.currentStage {
                        case "setting":
                            settingStageView
                        case "execution":
                            executionStageView
                        case "reflection":
                            reflectionStageView
                        case "completed":
                            completedStageView
                        default:
                            settingStageView
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(goal.title.isEmpty ? "새 목표" : goal.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }

    // MARK: - Stage Indicator
    private var stageIndicator: some View {
        HStack(spacing: 0) {
            stageButton(stage: "setting", number: 1, title: "목표 설정")
            stageConnector(isActive: goal.currentStage != "setting")
            stageButton(stage: "execution", number: 2, title: "실행")
            stageConnector(isActive: goal.currentStage == "reflection" || goal.currentStage == "completed")
            stageButton(stage: "reflection", number: 3, title: "회고")
        }
        .padding(.horizontal)
    }

    private func stageButton(stage: String, number: Int, title: String) -> some View {
        let isActive = isStageActive(stage)
        let isCurrent = goal.currentStage == stage

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.blue : (isActive ? Color.green : Color(.controlBackgroundColor)))
                    .frame(width: 36, height: 36)

                if isActive && !isCurrent {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.body.bold())
                        .foregroundStyle(isCurrent ? .white : .secondary)
                }
            }

            Text(title)
                .font(.body)
                .foregroundStyle(isCurrent ? .primary : .secondary)
        }
    }

    private func stageConnector(isActive: Bool) -> some View {
        Rectangle()
            .fill(isActive ? Color.green : Color(.controlBackgroundColor))
            .frame(height: 2)
            .frame(maxWidth: 60)
    }

    private func isStageActive(_ stage: String) -> Bool {
        let stages = ["setting", "execution", "reflection", "completed"]
        guard let currentIndex = stages.firstIndex(of: goal.currentStage),
              let stageIndex = stages.firstIndex(of: stage) else { return false }
        return stageIndex < currentIndex
    }

    // MARK: - 1단계: 목표 설정
    private var settingStageView: some View {
        VStack(alignment: .leading, spacing: 24) {
            stageHeader(
                icon: "target",
                title: "1단계: 목표 설정",
                subtitle: "달성하고 싶은 목표를 명확히 정의해보세요"
            )

            // 질문 1: 목표
            questionCard(
                number: 1,
                question: "달성하고 싶은 목표가 무엇인가요?",
                placeholder: "구체적이고 측정 가능한 목표를 작성해보세요",
                text: $goal.title,
                hint: "예: 매일 30분 운동하기, 새로운 프로그래밍 언어 배우기"
            )

            // 질문 2: 이유
            questionCard(
                number: 2,
                question: "왜 이 목표가 중요한가요?",
                placeholder: "이 목표를 달성하고 싶은 이유를 적어보세요",
                text: $goal.whyImportant,
                hint: "동기가 명확할수록 목표 달성 확률이 높아져요"
            )

            // 질문 3: 기대 변화
            questionCard(
                number: 3,
                question: "목표를 달성하면 어떤 변화가 있을까요?",
                placeholder: "목표 달성 후 예상되는 긍정적인 변화를 상상해보세요",
                text: $goal.expectedChange,
                hint: "예: 체력이 좋아진다, 취업 기회가 늘어난다"
            )

            // 질문 4: 성공 기준
            questionCard(
                number: 4,
                question: "목표 달성을 어떻게 측정할 수 있나요?",
                placeholder: "목표 달성 여부를 판단할 수 있는 구체적인 기준을 정해보세요",
                text: $goal.successCriteria,
                hint: "예: 일주일에 5일 이상 운동 완료, 프로젝트 하나 완성"
            )

            // 기한 설정
            datePickerSection

            // 다음 단계 버튼
            nextStageButton(
                title: "목표 설정 완료 → 실행 시작",
                isEnabled: goal.isSettingComplete,
                action: {
                    withAnimation {
                        goal.currentStage = "execution"
                    }
                }
            )
        }
    }

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("목표 기한 (선택)", systemImage: "calendar")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)

            HStack {
                if goal.targetDate != nil {
                    DatePicker("", selection: Binding(
                        get: { goal.targetDate ?? Date() },
                        set: { goal.targetDate = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()

                    Button {
                        goal.targetDate = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        goal.targetDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                    } label: {
                        Label("기한 설정하기", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 2단계: 실행
    private var executionStageView: some View {
        VStack(alignment: .leading, spacing: 24) {
            stageHeader(
                icon: "figure.run",
                title: "2단계: 실행",
                subtitle: "목표를 향해 꾸준히 전진해보세요"
            )

            // 목표 요약
            goalSummaryCard

            // 진행률
            progressSection

            // 오늘의 실행 기록
            executionLogSection

            // 회고로 이동 버튼
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        goal.currentStage = "setting"
                    }
                } label: {
                    Label("목표 수정", systemImage: "pencil")
                }
                .buttonStyle(.bordered)

                nextStageButton(
                    title: "실행 완료 → 회고하기",
                    isEnabled: goal.progressPercentage > 0,
                    action: {
                        withAnimation {
                            goal.currentStage = "reflection"
                        }
                    }
                )
            }
        }
    }

    private var goalSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("나의 목표", systemImage: "target")
                .font(.body.weight(.medium))
                .foregroundStyle(.blue)

            Text(goal.title)
                .font(.headline)
                .foregroundStyle(.primary)

            if !goal.whyImportant.isEmpty {
                Text("이유: \(goal.whyImportant)")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let targetDate = goal.targetDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(.body)
                    Text(goal.deadlineStatus)
                        .font(.body)
                }
                .foregroundStyle(goal.daysRemaining ?? 0 < 3 ? .orange : .secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("진행률", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.body.weight(.medium))

                Spacer()

                Text("\(goal.progressPercentage)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(progressColor)
            }

            // 진행률 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.controlBackgroundColor))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(goal.progressPercentage) / 100)
                }
            }
            .frame(height: 12)

            // 진행률 조절
            Slider(value: Binding(
                get: { Double(goal.progressPercentage) },
                set: { goal.progressPercentage = Int($0) }
            ), in: 0...100, step: 5)

            HStack {
                ForEach([0, 25, 50, 75, 100], id: \.self) { value in
                    Button {
                        withAnimation {
                            goal.progressPercentage = value
                        }
                    } label: {
                        Text("\(value)%")
                            .font(.body)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(goal.progressPercentage == value ? progressColor : Color(.controlBackgroundColor))
                            .foregroundStyle(goal.progressPercentage == value ? .white : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressColor: Color {
        if goal.progressPercentage < 30 { return .red }
        if goal.progressPercentage < 70 { return .orange }
        return .green
    }

    private var executionLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("실행 질문", systemImage: "questionmark.bubble")
                .font(.body.weight(.medium))
                .foregroundStyle(.orange)

            questionCard(
                number: 1,
                question: "오늘 목표를 위해 무엇을 했나요?",
                placeholder: "오늘 실행한 활동을 기록해보세요",
                text: $goal.progressNotes,
                hint: "작은 실천도 모두 기록해보세요"
            )
        }
    }

    // MARK: - 3단계: 회고
    private var reflectionStageView: some View {
        VStack(alignment: .leading, spacing: 24) {
            stageHeader(
                icon: "brain.head.profile",
                title: "3단계: 회고",
                subtitle: "지나온 과정을 돌아보며 배움을 얻어보세요"
            )

            // 목표 & 진행 요약
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("목표")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(goal.title)
                        .font(.body.weight(.medium))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("진행률")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("\(goal.progressPercentage)%")
                        .font(.headline)
                        .foregroundStyle(progressColor)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 회고 질문들
            questionCard(
                number: 1,
                question: "잘 된 점은 무엇인가요?",
                placeholder: "목표를 향해 나아가며 잘했다고 생각되는 점을 적어보세요",
                text: $goal.whatWentWell,
                hint: "작은 성공도 모두 인정해주세요",
                isRequired: true
            )

            questionCard(
                number: 2,
                question: "아쉬운 점은 무엇인가요?",
                placeholder: "개선할 수 있었던 부분이나 아쉬웠던 점을 적어보세요",
                text: $goal.whatCouldImprove,
                hint: "비난이 아닌 개선의 관점으로 바라봐주세요"
            )

            questionCard(
                number: 3,
                question: "배운 점은 무엇인가요?",
                placeholder: "이 과정을 통해 새롭게 알게 된 것을 적어보세요",
                text: $goal.lessonsLearned,
                hint: "성공과 실패 모두에서 배울 수 있어요",
                isRequired: true
            )

            questionCard(
                number: 4,
                question: "다음에 다르게 하고 싶은 것은?",
                placeholder: "다음 목표에 적용하고 싶은 개선 사항을 적어보세요",
                text: $goal.nextActions,
                hint: "구체적인 행동 계획을 세워보세요"
            )

            // 완료 버튼
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        goal.currentStage = "execution"
                    }
                } label: {
                    Label("실행으로 돌아가기", systemImage: "arrow.left")
                }
                .buttonStyle(.bordered)

                nextStageButton(
                    title: "회고 완료",
                    isEnabled: goal.isReflectionComplete,
                    action: {
                        withAnimation {
                            goal.currentStage = "completed"
                            goal.isCompleted = true
                            goal.completedAt = Date()
                        }
                    }
                )
            }
        }
    }

    // MARK: - 완료 화면
    private var completedStageView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("회고 완료!")
                .font(.title.bold())
                .foregroundStyle(.primary)

            Text("목표를 향한 여정을 마무리했습니다.\n배운 점을 다음 목표에 활용해보세요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // 요약 카드
            VStack(alignment: .leading, spacing: 16) {
                summaryRow(title: "목표", content: goal.title)
                summaryRow(title: "달성률", content: "\(goal.progressPercentage)%")
                summaryRow(title: "잘 된 점", content: goal.whatWentWell)
                summaryRow(title: "배운 점", content: goal.lessonsLearned)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("닫기")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func summaryRow(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Reusable Components
    private func stageHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private func questionCard(
        number: Int,
        question: String,
        placeholder: String,
        text: Binding<String>,
        hint: String,
        isRequired: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("Q\(number)")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.blue)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(question)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)

                        if isRequired {
                            Text("필수")
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }

                    Text(hint)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            TextEditor(text: text)
                .font(.body)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    Group {
                        if text.wrappedValue.isEmpty {
                            Text(placeholder)
                                .font(.body)
                                .foregroundStyle(.secondary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func nextStageButton(title: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled)
    }
}

#Preview {
    ReflectionFlowView(goal: Goal(title: "테스트 목표"))
        .modelContainer(for: Goal.self, inMemory: true)
}
