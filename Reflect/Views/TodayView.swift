import SwiftUI
import SwiftData

// MARK: - 회고 탭 (목표 + 병목 지점 기록)
struct DailyLogView: View {
    @Binding var selectedEntry: BottleneckEntry?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BottleneckEntry.createdAt, order: .reverse) private var allEntries: [BottleneckEntry]
    @Query(sort: \Goal.priority) private var goals: [Goal]
    @Query(sort: \DailyRetrospective.date, order: .reverse) private var retrospectives: [DailyRetrospective]

    // 입력 폼 상태
    @State private var isAddingEntry = false
    @State private var isAddingGoal = false
    @Environment(\.openWindow) private var openWindow

    // 오늘의 5분 회고
    private var todayRetrospective: DailyRetrospective? {
        retrospectives.first { $0.isToday }
    }

    // 어제의 5분 회고
    private var yesterdayRetrospective: DailyRetrospective? {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        return retrospectives.first { Calendar.current.startOfDay(for: $0.date) == yesterdayStart }
    }

    // 병목 지점 입력 필드
    @State private var taskName = ""
    @State private var estimatedMinutes = 30
    @State private var actualMinutes = 30
    @State private var delayReason = ""
    @State private var weeklyFrequency = 1
    @State private var automationScore = 3
    @State private var tagsString = ""
    @State private var notes = ""

    // 5분 회고 입력 필드
    @State private var retroGood = ""
    @State private var retroBad = ""
    @State private var retroIdeas = ""
    @State private var retroActions = ""
    @State private var retroLoaded = false
    @State private var isRetroEditMode = false

    // 어제 액션 리뷰 필드
    @State private var previousActionsStatus = "none"
    @State private var previousActionsReview = ""
    @State private var previousActionsLoaded = false

    // 목표 입력 필드
    @State private var goalTitle = ""
    @State private var goalDescription = ""
    @State private var goalCategory = "productivity"
    @State private var goalTargetDate = Date()
    @State private var goalHasDeadline = false
    @State private var goalPriority = 2

    private var todayEntries: [BottleneckEntry] {
        allEntries.filter { $0.isToday }
    }

    private var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    private var todayWastedMinutes: Int {
        todayEntries.reduce(0) { $0 + $1.wastedMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                headerSection

                // 5분 회고 섹션
                dailyRetrospectiveSection

                Divider()

                // 목표 섹션
                goalsSection

                Divider()

                // 병목 지점 입력/목록 섹션
                bottleneckSection
            }
            .padding(24)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.title.bold())
                        .foregroundStyle(.primary)

                    Text(todayDateString)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 오늘의 요약
                if !todayEntries.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(todayEntries.count)개 기록")
                            .font(.headline)
                            .foregroundStyle(.blue)

                        if todayWastedMinutes > 0 {
                            Text("+\(BottleneckEntry.formatMinutes(todayWastedMinutes)) 낭비")
                                .font(.body)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "좋은 아침이에요 ☀️"
        case 12..<17: return "오후도 화이팅 💪"
        case 17..<21: return "오늘 하루 어땠나요? 🌙"
        default: return "늦은 시간까지 수고하셨어요 ✨"
        }
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }

    // MARK: - Daily Retrospective Section (5분 회고)
    private var hasSavedRetrospective: Bool {
        todayRetrospective?.hasContent ?? false
    }

    private var isEditingRetro: Bool {
        !hasSavedRetrospective || isRetroEditMode
    }

    private var dailyRetrospectiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("5분 회고", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if hasSavedRetrospective && !isRetroEditMode {
                    // 편집 버튼
                    Button {
                        isRetroEditMode = true
                    } label: {
                        Label("편집", systemImage: "pencil")
                            .font(.body)
                    }
                    .buttonStyle(.bordered)
                } else {
                    // 저장/취소 버튼
                    if hasSavedRetrospective {
                        Button {
                            // 취소 - 원래 값으로 복원
                            loadRetrospective(force: true)
                            isRetroEditMode = false
                        } label: {
                            Text("취소")
                                .font(.body)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        saveRetrospective()
                        isRetroEditMode = false
                    } label: {
                        Label("저장", systemImage: "checkmark.circle.fill")
                            .font(.body)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(!hasRetrospectiveChanges && !hasSavedRetrospective)
                }
            }

            // 어제 액션 리뷰 (어제 액션이 있는 경우에만 표시)
            if let yesterday = yesterdayRetrospective, !yesterday.actions.isEmpty {
                previousActionsReviewSection(yesterdayActions: yesterday.actions)
            }

            // 오늘 회고 카드
            if isEditingRetro {
                // 편집 모드: 입력 필드
                VStack(spacing: 12) {
                    RetrospectiveInputRow(
                        emoji: "😊",
                        title: "Good",
                        subtitle: "잘된 것",
                        text: $retroGood,
                        placeholder: "오늘 잘한 일이나 좋았던 점을 적어보세요"
                    )

                    RetrospectiveInputRow(
                        emoji: "😞",
                        title: "Bad",
                        subtitle: "아쉬운 것",
                        text: $retroBad,
                        placeholder: "아쉬웠던 점이나 개선하고 싶은 것을 적어보세요"
                    )

                    RetrospectiveInputRow(
                        emoji: "💡",
                        title: "Ideas",
                        subtitle: "개선 아이디어",
                        text: $retroIdeas,
                        placeholder: "떠오른 아이디어나 시도해보고 싶은 것을 적어보세요"
                    )

                    RetrospectiveInputRow(
                        emoji: "⚡",
                        title: "Actions",
                        subtitle: "당장 실행할 것",
                        text: $retroActions,
                        placeholder: "내일 바로 실행할 수 있는 작은 액션을 적어보세요"
                    )
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // 읽기 모드: 저장된 내용 표시
                VStack(spacing: 10) {
                    if let retro = todayRetrospective {
                        RetrospectiveReadOnlyRow(emoji: "😊", title: "Good", content: retro.good)
                        RetrospectiveReadOnlyRow(emoji: "😞", title: "Bad", content: retro.bad)
                        RetrospectiveReadOnlyRow(emoji: "💡", title: "Ideas", content: retro.ideas)
                        RetrospectiveReadOnlyRow(emoji: "⚡", title: "Actions", content: retro.actions)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            loadRetrospective()
            loadPreviousActionsReview()
        }
        .onChange(of: todayRetrospective) { _, _ in
            loadRetrospective()
        }
    }

    // MARK: - Previous Actions Review Section
    private func previousActionsReviewSection(yesterdayActions: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundStyle(.orange)
                Text("어제의 액션 돌아보기")
                    .font(.body.bold())
                    .foregroundStyle(.primary)
            }

            // 어제 작성한 액션
            VStack(alignment: .leading, spacing: 8) {
                Text("어제 계획한 액션:")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text(yesterdayActions)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.textBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 완료 상태 선택
            VStack(alignment: .leading, spacing: 8) {
                Text("실행 결과:")
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    PreviousActionStatusButton(
                        title: "완료",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        isSelected: previousActionsStatus == "completed"
                    ) {
                        previousActionsStatus = "completed"
                    }

                    PreviousActionStatusButton(
                        title: "부분 완료",
                        icon: "circle.lefthalf.filled",
                        color: .orange,
                        isSelected: previousActionsStatus == "partial"
                    ) {
                        previousActionsStatus = "partial"
                    }

                    PreviousActionStatusButton(
                        title: "미완료",
                        icon: "xmark.circle.fill",
                        color: .red,
                        isSelected: previousActionsStatus == "skipped"
                    ) {
                        previousActionsStatus = "skipped"
                    }
                }
            }

            // 회고 코멘트
            if previousActionsStatus != "none" {
                VStack(alignment: .leading, spacing: 4) {
                    Text(previousActionsStatus == "completed" ? "잘했어요! 어떻게 완료했나요?" :
                         previousActionsStatus == "partial" ? "어디까지 진행했나요?" :
                         "무엇이 방해가 되었나요?")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    TextField("짧게 회고를 남겨보세요", text: $previousActionsReview, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .lineLimit(1...3)
                        .padding(8)
                        .background(Color(.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var hasRetrospectiveChanges: Bool {
        let current = todayRetrospective
        let contentChanged = retroGood != (current?.good ?? "") ||
               retroBad != (current?.bad ?? "") ||
               retroIdeas != (current?.ideas ?? "") ||
               retroActions != (current?.actions ?? "")

        let previousActionsChanged = previousActionsStatus != (current?.previousActionsStatus ?? "none") ||
               previousActionsReview != (current?.previousActionsReview ?? "")

        return contentChanged || previousActionsChanged
    }

    private func loadRetrospective(force: Bool = false) {
        guard !retroLoaded || force else { return }
        if let retro = todayRetrospective {
            retroGood = retro.good
            retroBad = retro.bad
            retroIdeas = retro.ideas
            retroActions = retro.actions
            retroLoaded = true
        }
    }

    private func loadPreviousActionsReview() {
        guard !previousActionsLoaded else { return }
        if let retro = todayRetrospective {
            previousActionsStatus = retro.previousActionsStatus
            previousActionsReview = retro.previousActionsReview
            previousActionsLoaded = true
        }
    }

    private func saveRetrospective() {
        let retro: DailyRetrospective
        if let existing = todayRetrospective {
            retro = existing
        } else {
            retro = DailyRetrospective()
            modelContext.insert(retro)
        }

        retro.good = retroGood
        retro.bad = retroBad
        retro.ideas = retroIdeas
        retro.actions = retroActions
        retro.previousActionsStatus = previousActionsStatus
        retro.previousActionsReview = previousActionsReview
        retro.updatedAt = Date()

        retroLoaded = true
        previousActionsLoaded = true
    }

    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("목표", systemImage: "target")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAddingGoal.toggle()
                        if isAddingGoal {
                            isAddingEntry = false
                        }
                    }
                } label: {
                    Label(isAddingGoal ? "취소" : "목표 추가", systemImage: isAddingGoal ? "xmark" : "plus")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .tint(isAddingGoal ? .red : .blue)
            }

            // 목표 입력 폼
            if isAddingGoal {
                goalInputForm
            }

            // 활성 목표 목록
            if activeGoals.isEmpty && !isAddingGoal {
                Text("설정된 목표가 없습니다. 목표를 추가해보세요!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(activeGoals) { goal in
                    GoalRowView(goal: goal) {
                        // 새 창에서 회고 플로우 열기
                        openWindow(value: goal.id.uuidString)
                    } onDelete: {
                        modelContext.delete(goal)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Goal Input Form
    private var goalInputForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 제목
            VStack(alignment: .leading, spacing: 6) {
                Text("목표 제목")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("예: 반복 작업 3개 자동화하기", text: $goalTitle)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 설명
            VStack(alignment: .leading, spacing: 6) {
                Text("상세 설명 (선택)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("목표에 대한 상세 설명", text: $goalDescription)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 16) {
                // 카테고리
                VStack(alignment: .leading, spacing: 6) {
                    Text("카테고리")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Picker("카테고리", selection: $goalCategory) {
                        Text("생산성").tag("productivity")
                        Text("자동화").tag("automation")
                        Text("학습").tag("learning")
                        Text("프로세스").tag("process")
                    }
                    .pickerStyle(.menu)
                }

                // 우선순위
                VStack(alignment: .leading, spacing: 6) {
                    Text("우선순위")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Picker("우선순위", selection: $goalPriority) {
                        Text("높음").tag(1)
                        Text("보통").tag(2)
                        Text("낮음").tag(3)
                    }
                    .pickerStyle(.segmented)
                }
            }

            // 기한
            HStack {
                Toggle("기한 설정", isOn: $goalHasDeadline)
                    .toggleStyle(.switch)

                if goalHasDeadline {
                    DatePicker("", selection: $goalTargetDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            // 저장 버튼
            Button {
                saveGoal()
            } label: {
                Text("목표 저장")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(goalTitle.isEmpty)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func saveGoal() {
        let goal = Goal(
            title: goalTitle,
            goalDescription: goalDescription,
            category: goalCategory,
            targetDate: goalHasDeadline ? goalTargetDate : nil,
            priority: goalPriority
        )
        modelContext.insert(goal)

        // 초기화
        goalTitle = ""
        goalDescription = ""
        goalCategory = "productivity"
        goalTargetDate = Date()
        goalHasDeadline = false
        goalPriority = 2
        isAddingGoal = false
    }

    // MARK: - Bottleneck Section
    private var bottleneckSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("병목 지점 기록", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAddingEntry.toggle()
                        if isAddingEntry {
                            isAddingGoal = false
                        }
                    }
                } label: {
                    Label(isAddingEntry ? "취소" : "기록 추가", systemImage: isAddingEntry ? "xmark" : "plus")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .tint(isAddingEntry ? .red : .orange)
            }

            // 병목 지점 입력 폼
            if isAddingEntry {
                entryInputForm
            }

            // 오늘의 기록 목록
            if todayEntries.isEmpty && !isAddingEntry {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.green.opacity(0.6))

                    Text("오늘은 아직 기록이 없어요")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else if !todayEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("오늘의 기록")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    ForEach(todayEntries) { entry in
                        EntryRowView(entry: entry, isSelected: selectedEntry?.id == entry.id)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedEntry = entry
                                }
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Entry Input Form
    private var entryInputForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 작업명
            VStack(alignment: .leading, spacing: 6) {
                Text("작업명")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("비효율적이었던 작업명", text: $taskName)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 시간 입력
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("예상 시간")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    HStack {
                        Stepper("", value: $estimatedMinutes, in: 1...480, step: 5)
                            .labelsHidden()
                        Text("\(estimatedMinutes)분")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.green)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("실제 시간")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    HStack {
                        Stepper("", value: $actualMinutes, in: 1...480, step: 5)
                            .labelsHidden()
                        Text("\(actualMinutes)분")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(actualMinutes > estimatedMinutes ? .red : .primary)
                    }
                }

                if actualMinutes > estimatedMinutes {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("낭비")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("+\(actualMinutes - estimatedMinutes)분")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.red)
                    }
                }
            }

            // 지연 원인
            VStack(alignment: .leading, spacing: 6) {
                Text("지연 원인 (선택)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("왜 예상보다 오래 걸렸나요?", text: $delayReason)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 20) {
                // 주간 반복
                VStack(alignment: .leading, spacing: 6) {
                    Text("주간 반복")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    HStack {
                        Stepper("", value: $weeklyFrequency, in: 1...20)
                            .labelsHidden()
                        Text("\(weeklyFrequency)회")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.blue)
                    }
                }

                // 도구화 가능성
                VStack(alignment: .leading, spacing: 6) {
                    Text("도구화 가능성")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { score in
                            Button {
                                automationScore = score
                            } label: {
                                Image(systemName: score <= automationScore ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundStyle(score <= automationScore ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // 태그
            VStack(alignment: .leading, spacing: 6) {
                Text("태그 (쉼표로 구분)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("예: 데이터처리, 문서작업", text: $tagsString)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 저장 버튼
            Button {
                saveEntry()
            } label: {
                Text("기록 저장")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(taskName.isEmpty)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func saveEntry() {
        let entry = BottleneckEntry(
            taskName: taskName,
            estimatedMinutes: estimatedMinutes,
            actualMinutes: actualMinutes,
            delayReason: delayReason,
            weeklyFrequency: weeklyFrequency,
            automationScore: automationScore,
            tags: tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            notes: notes
        )
        modelContext.insert(entry)

        // 초기화
        taskName = ""
        estimatedMinutes = 30
        actualMinutes = 30
        delayReason = ""
        weeklyFrequency = 1
        automationScore = 3
        tagsString = ""
        notes = ""
        isAddingEntry = false
    }
}

// MARK: - Goal Row View
struct GoalRowView: View {
    let goal: Goal
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 단계 아이콘
            Image(systemName: goal.stageIcon)
                .font(.title2)
                .foregroundStyle(stageColor)

            // 정보
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(goal.title.isEmpty ? "새 목표" : goal.title)
                        .font(.body.weight(.medium))
                        .foregroundColor(goal.isCompleted ? .secondary : .primary)
                        .strikethrough(goal.isCompleted)
                        .lineLimit(1)

                    Spacer()

                    // 진행률 (실행 단계 이상일 때)
                    if goal.currentStage != "setting" {
                        Text("\(goal.progressPercentage)%")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(progressColor)
                    }
                }

                HStack(spacing: 8) {
                    // 단계 배지
                    Text(goal.stageText)
                        .font(.body.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(stageColor.opacity(0.2))
                        .foregroundStyle(stageColor)
                        .clipShape(Capsule())

                    // 카테고리
                    HStack(spacing: 2) {
                        Image(systemName: goal.categoryIcon)
                            .font(.body)
                        Text(goal.categoryText)
                            .font(.body)
                    }
                    .foregroundStyle(.secondary)

                    // 기한
                    if goal.targetDate != nil {
                        Text(goal.deadlineStatus)
                            .font(.body)
                            .foregroundStyle(deadlineColor)
                    }
                }
            }

            // 삭제 버튼
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)

            // 화살표
            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var stageColor: Color {
        switch goal.currentStage {
        case "setting": return .blue
        case "execution": return .orange
        case "reflection": return .purple
        case "completed": return .green
        default: return .gray
        }
    }

    private var progressColor: Color {
        if goal.progressPercentage < 30 { return .red }
        if goal.progressPercentage < 70 { return .orange }
        return .green
    }

    private var deadlineColor: Color {
        guard let days = goal.daysRemaining else { return .secondary }
        if days < 0 { return .red }
        if days <= 2 { return .orange }
        return .secondary
    }
}

// MARK: - Entry Row View
struct EntryRowView: View {
    let entry: BottleneckEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 도구화 가능성 점수 인디케이터
            VStack(spacing: 4) {
                Text(entry.automationEmoji)
                    .font(.title2)
                Text("\(entry.automationScore)")
                    .font(.body.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)

            // 메인 콘텐츠
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.taskName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    // 시간 정보
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.body)
                        Text("\(entry.estimatedMinutes)분 → \(entry.actualMinutes)분")
                            .font(.body)
                    }
                    .foregroundStyle(.secondary)

                    // 낭비 시간
                    if entry.wastedMinutes > 0 {
                        Text("+\(entry.wastedMinutes)분")
                            .font(.body.bold())
                            .foregroundStyle(.red)
                    }

                    // 반복 빈도
                    HStack(spacing: 2) {
                        Image(systemName: "repeat")
                            .font(.body)
                        Text("주 \(entry.weeklyFrequency)회")
                            .font(.body)
                    }
                    .foregroundStyle(.blue)
                }

                // 태그
                if !entry.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(entry.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.body)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        if entry.tags.count > 3 {
                            Text("+\(entry.tags.count - 3)")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // ROI 점수
            VStack(alignment: .trailing, spacing: 2) {
                Text("ROI")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f", entry.roiScore))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.purple)
            }

            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.2) : Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.taskName), 도구화 점수 \(entry.automationScore)점, 낭비 시간 \(entry.wastedMinutes)분")
    }
}

// MARK: - Edit Entry Sheet (기존 유지)
struct EditEntrySheet: View {
    let entry: BottleneckEntry
    @Environment(\.dismiss) private var dismiss

    @State private var taskName: String
    @State private var estimatedMinutes: Int
    @State private var actualMinutes: Int
    @State private var delayReason: String
    @State private var weeklyFrequency: Int
    @State private var automationScore: Int
    @State private var tagsString: String
    @State private var notes: String

    init(entry: BottleneckEntry) {
        self.entry = entry
        _taskName = State(initialValue: entry.taskName)
        _estimatedMinutes = State(initialValue: entry.estimatedMinutes)
        _actualMinutes = State(initialValue: entry.actualMinutes)
        _delayReason = State(initialValue: entry.delayReason)
        _weeklyFrequency = State(initialValue: entry.weeklyFrequency)
        _automationScore = State(initialValue: entry.automationScore)
        _tagsString = State(initialValue: entry.tags.joined(separator: ", "))
        _notes = State(initialValue: entry.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("작업 정보") {
                    TextField("작업명", text: $taskName)
                    TextField("지연 원인", text: $delayReason)
                }

                Section("시간 (분)") {
                    HStack {
                        Text("예상 시간")
                        Spacer()
                        Stepper("\(estimatedMinutes)분", value: $estimatedMinutes, in: 1...480, step: 5)
                            .labelsHidden()
                        Text("\(estimatedMinutes)분")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }

                    HStack {
                        Text("실제 시간")
                        Spacer()
                        Stepper("\(actualMinutes)분", value: $actualMinutes, in: 1...480, step: 5)
                            .labelsHidden()
                        Text("\(actualMinutes)분")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                }

                Section("반복 및 자동화") {
                    HStack {
                        Text("주간 반복")
                        Spacer()
                        Stepper("\(weeklyFrequency)회", value: $weeklyFrequency, in: 1...20)
                            .labelsHidden()
                        Text("\(weeklyFrequency)회")
                            .monospacedDigit()
                    }

                    HStack(spacing: 8) {
                        Text("도구화 점수")
                        Spacer()
                        ForEach(1...5, id: \.self) { score in
                            Button {
                                automationScore = score
                            } label: {
                                Image(systemName: score <= automationScore ? "star.fill" : "star")
                                    .foregroundStyle(score <= automationScore ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("태그") {
                    TextField("태그 (쉼표로 구분)", text: $tagsString)
                }

                Section("메모") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("기록 수정")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { saveChanges() }
                        .disabled(taskName.isEmpty)
                }
            }
        }
        .frame(minWidth: 450, minHeight: 500)
    }

    private func saveChanges() {
        entry.taskName = taskName
        entry.estimatedMinutes = estimatedMinutes
        entry.actualMinutes = actualMinutes
        entry.delayReason = delayReason
        entry.weeklyFrequency = weeklyFrequency
        entry.automationScore = automationScore
        entry.tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        entry.notes = notes
        dismiss()
    }
}

// MARK: - Retrospective Input Row
struct RetrospectiveInputRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    @Binding var text: String
    let placeholder: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 이모지 + 제목
            VStack(alignment: .leading, spacing: 2) {
                Text(emoji)
                    .font(.title2)
                Text(title)
                    .font(.body.bold())
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70, alignment: .leading)

            // 입력 필드
            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...4)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focused($isFocused)
        }
    }
}

// MARK: - Previous Action Status Button
struct PreviousActionStatusButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.body)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.2) : Color(.controlBackgroundColor))
            .foregroundStyle(isSelected ? color : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Retrospective Read Only Row
struct RetrospectiveReadOnlyRow: View {
    let emoji: String
    let title: String
    let content: String

    var body: some View {
        if !content.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                // 이모지 + 제목
                VStack(alignment: .leading, spacing: 2) {
                    Text(emoji)
                        .font(.title2)
                    Text(title)
                        .font(.body.bold())
                        .foregroundStyle(.primary)
                }
                .frame(width: 70, alignment: .leading)

                // 내용
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview("DailyLogView") {
    DailyLogView(selectedEntry: .constant(nil))
        .modelContainer(for: [BottleneckEntry.self, Goal.self, DailyRetrospective.self], inMemory: true)
        .frame(width: 600, height: 800)
}
