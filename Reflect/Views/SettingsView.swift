import SwiftUI
import SwiftData

// MARK: - Tool Tracker View (도구 개발 트래커)
struct ToolTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ToolDevelopment.toolName) private var tools: [ToolDevelopment]
    @Query(sort: \BottleneckEntry.createdAt, order: .reverse) private var entries: [BottleneckEntry]

    @State private var showingNewToolSheet = false
    @State private var selectedTool: ToolDevelopment?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                headerSection

                // 통계 요약
                statsSection

                // 도구 목록
                if tools.isEmpty {
                    emptyState
                } else {
                    toolsList
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showingNewToolSheet) {
            NewToolSheet(entries: entries)
        }
        .sheet(item: $selectedTool) { tool in
            EditToolSheet(tool: tool)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("도구 개발 트래커")
                    .font(.title.bold())
                    .foregroundStyle(.primary)

                Text("자동화 도구의 개발 진행 상황을 추적하세요")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingNewToolSheet = true
            } label: {
                Label("새 도구", systemImage: "plus")
                    .font(.body.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            ToolStatCard(
                title: "전체 도구",
                value: "\(tools.count)",
                icon: "hammer.fill",
                color: .purple
            )

            ToolStatCard(
                title: "개발중",
                value: "\(tools.filter { $0.status == "developing" }.count)",
                icon: "wrench.and.screwdriver.fill",
                color: .orange
            )

            ToolStatCard(
                title: "완료",
                value: "\(tools.filter { $0.status == "completed" }.count)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            let totalSaving = tools
                .filter { $0.status == "completed" }
                .reduce(0) { $0 + $1.actualSavingMinutes }
            ToolStatCard(
                title: "총 절감 시간",
                value: "\(totalSaving)분/주",
                icon: "clock.badge.checkmark",
                color: .blue
            )
        }
    }

    // MARK: - Tools List
    private var toolsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("도구 목록")
                .font(.headline)
                .foregroundStyle(.primary)

            ForEach(tools) { tool in
                ToolRowView(tool: tool)
                    .onTapGesture {
                        selectedTool = tool
                    }
                    .contextMenu {
                        Button {
                            selectedTool = tool
                        } label: {
                            Label("편집", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            modelContext.delete(tool)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.circle")
                .font(.system(size: 64))
                .foregroundStyle(.purple.opacity(0.5))

            Text("등록된 도구가 없습니다")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("병목 지점을 해결하기 위한\n자동화 도구를 등록해보세요")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingNewToolSheet = true
            } label: {
                Label("첫 도구 등록하기", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Tool Stat Card
struct ToolStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.primary)

            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Tool Row View
struct ToolRowView: View {
    let tool: ToolDevelopment

    var body: some View {
        HStack(spacing: 16) {
            // 상태 아이콘
            Text(tool.statusIcon)
                .font(.title2)

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(tool.toolName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(tool.targetBottleneck)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    // 상태
                    Text(tool.statusText)
                        .font(.body.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())

                    // 예상 절감 시간
                    if tool.expectedSavingMinutes > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.body)
                            Text("주 \(tool.expectedSavingMinutes)분 절감")
                                .font(.body)
                        }
                        .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            // ROI
            if tool.status == "completed" && tool.calculatedROI > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ROI")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1fx", tool.calculatedROI))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.purple)
                }
            }

            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        switch tool.status {
        case "planning": return .blue
        case "developing": return .orange
        case "completed": return .green
        case "abandoned": return .red
        default: return .gray
        }
    }
}

// MARK: - New Tool Sheet
struct NewToolSheet: View {
    let entries: [BottleneckEntry]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var toolName = ""
    @State private var targetBottleneck = ""
    @State private var status = "planning"
    @State private var estimatedDevMinutes = 60
    @State private var expectedSavingMinutes = 30
    @State private var notes = ""

    let statusOptions = [
        ("planning", "계획중"),
        ("developing", "개발중"),
        ("completed", "완료"),
        ("abandoned", "폐기")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("도구명", text: $toolName)

                    Picker("목표 병목 지점", selection: $targetBottleneck) {
                        Text("직접 입력").tag("")
                        ForEach(entries.prefix(10), id: \.id) { entry in
                            Text(entry.taskName).tag(entry.taskName)
                        }
                    }

                    if targetBottleneck.isEmpty {
                        TextField("병목 지점 설명", text: $targetBottleneck)
                    }

                    Picker("상태", selection: $status) {
                        ForEach(statusOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }

                Section("시간 정보 (분)") {
                    Stepper("예상 개발 시간: \(estimatedDevMinutes)분",
                            value: $estimatedDevMinutes, in: 10...600, step: 10)

                    Stepper("예상 절감 시간: \(expectedSavingMinutes)분/주",
                            value: $expectedSavingMinutes, in: 5...300, step: 5)
                }

                Section("메모") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("새 도구 등록")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { saveTool() }
                        .disabled(toolName.isEmpty)
                }
            }
        }
        .frame(minWidth: 450, minHeight: 450)
    }

    private func saveTool() {
        let tool = ToolDevelopment(
            toolName: toolName,
            targetBottleneck: targetBottleneck,
            status: status,
            startDate: status == "developing" ? Date() : nil,
            estimatedDevMinutes: estimatedDevMinutes,
            expectedSavingMinutes: expectedSavingMinutes,
            notes: notes
        )
        modelContext.insert(tool)
        dismiss()
    }
}

// MARK: - Edit Tool Sheet
struct EditToolSheet: View {
    let tool: ToolDevelopment
    @Environment(\.dismiss) private var dismiss

    @State private var toolName: String
    @State private var targetBottleneck: String
    @State private var status: String
    @State private var estimatedDevMinutes: Int
    @State private var actualDevMinutes: Int
    @State private var expectedSavingMinutes: Int
    @State private var actualSavingMinutes: Int
    @State private var notes: String

    let statusOptions = [
        ("planning", "계획중"),
        ("developing", "개발중"),
        ("completed", "완료"),
        ("abandoned", "폐기")
    ]

    init(tool: ToolDevelopment) {
        self.tool = tool
        _toolName = State(initialValue: tool.toolName)
        _targetBottleneck = State(initialValue: tool.targetBottleneck)
        _status = State(initialValue: tool.status)
        _estimatedDevMinutes = State(initialValue: tool.estimatedDevMinutes)
        _actualDevMinutes = State(initialValue: tool.actualDevMinutes)
        _expectedSavingMinutes = State(initialValue: tool.expectedSavingMinutes)
        _actualSavingMinutes = State(initialValue: tool.actualSavingMinutes)
        _notes = State(initialValue: tool.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("도구명", text: $toolName)
                    TextField("목표 병목 지점", text: $targetBottleneck)

                    Picker("상태", selection: $status) {
                        ForEach(statusOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }

                Section("개발 시간 (분)") {
                    Stepper("예상: \(estimatedDevMinutes)분",
                            value: $estimatedDevMinutes, in: 10...600, step: 10)
                    Stepper("실제: \(actualDevMinutes)분",
                            value: $actualDevMinutes, in: 0...600, step: 10)
                }

                Section("절감 시간 (분/주)") {
                    Stepper("예상: \(expectedSavingMinutes)분",
                            value: $expectedSavingMinutes, in: 5...300, step: 5)
                    Stepper("실제: \(actualSavingMinutes)분",
                            value: $actualSavingMinutes, in: 0...300, step: 5)
                }

                Section("메모") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("도구 편집")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { saveChanges() }
                        .disabled(toolName.isEmpty)
                }
            }
        }
        .frame(minWidth: 450, minHeight: 500)
    }

    private func saveChanges() {
        tool.toolName = toolName
        tool.targetBottleneck = targetBottleneck
        tool.status = status
        tool.estimatedDevMinutes = estimatedDevMinutes
        tool.actualDevMinutes = actualDevMinutes
        tool.expectedSavingMinutes = expectedSavingMinutes
        tool.actualSavingMinutes = actualSavingMinutes
        tool.notes = notes

        if status == "developing" && tool.startDate == nil {
            tool.startDate = Date()
        }
        if status == "completed" && tool.completedDate == nil {
            tool.completedDate = Date()
        }

        dismiss()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [BottleneckEntry]
    @Query private var tools: [ToolDevelopment]
    @Query private var goals: [Goal]
    @Query private var retrospectives: [DailyRetrospective]
    @Query private var questionLogs: [QuestionLog]

    @AppStorage("defaultAutomationScore") private var defaultAutomationScore: Int = 3
    @AppStorage("defaultWeeklyFrequency") private var defaultWeeklyFrequency: Int = 1

    @State private var showingResetAlert = false
    @State private var showingExportAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더
                headerSection

                // 설정 섹션들
                VStack(spacing: 20) {
                    defaultsSettings
                    dataSettings
                    aboutSection
                }
                .frame(maxWidth: 600)
            }
            .padding(24)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("설정")
                    .font(.title.bold())
                    .foregroundStyle(.primary)

                Text("앱을 나에게 맞게 커스터마이즈하세요")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Defaults Settings
    private var defaultsSettings: some View {
        settingsSection(title: "기본값", icon: "slider.horizontal.3", color: .yellow) {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("기본 도구화 가능성 점수")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { score in
                            Button {
                                defaultAutomationScore = score
                            } label: {
                                Image(systemName: score <= defaultAutomationScore ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(score <= defaultAutomationScore ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()

                HStack {
                    Text("기본 주간 반복 횟수")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper("\(defaultWeeklyFrequency)회", value: $defaultWeeklyFrequency, in: 1...20)
                        .labelsHidden()

                    Text("\(defaultWeeklyFrequency)회")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Data Settings
    private var dataSettings: some View {
        settingsSection(title: "데이터", icon: "externaldrive.fill", color: .green) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("병목 지점 기록")
                        Text("저장된 모든 기록")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(entries.count)개")
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("도구 개발 기록")
                        Text("등록된 자동화 도구")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(tools.count)개")
                        .font(.headline)
                        .foregroundStyle(.purple)
                }

                Divider()

                Button {
                    showingExportAlert = true
                } label: {
                    Label("CSV로 내보내기", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .alert("내보내기", isPresented: $showingExportAlert) {
                    Button("확인") { }
                } message: {
                    Text("곧 지원될 예정입니다!")
                }

                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Label("모든 데이터 삭제", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .alert("정말 삭제하시겠어요?", isPresented: $showingResetAlert) {
                    Button("취소", role: .cancel) { }
                    Button("삭제", role: .destructive) {
                        deleteAllData()
                    }
                } message: {
                    Text("모든 기록이 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
                }
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        settingsSection(title: "앱 정보", icon: "info.circle.fill", color: .blue) {
            VStack(spacing: 12) {
                HStack {
                    Text("앱 이름")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("FlowOptimizer")
                        .foregroundStyle(.primary)
                }

                HStack {
                    Text("버전")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.primary)
                }

                Divider()

                Text("반복되는 비효율적인 작업을 기록하고\n자동화 도구 개발 우선순위를 도출하는 생산성 회고 앱")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Helpers
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func deleteAllData() {
        for entry in entries {
            modelContext.delete(entry)
        }
        for tool in tools {
            modelContext.delete(tool)
        }
        for goal in goals {
            modelContext.delete(goal)
        }
        for retro in retrospectives {
            modelContext.delete(retro)
        }
        for log in questionLogs {
            modelContext.delete(log)
        }
    }
}

#Preview("ToolTrackerView") {
    ToolTrackerView()
        .modelContainer(for: [BottleneckEntry.self, ToolDevelopment.self], inMemory: true)
        .frame(width: 600, height: 700)
}

#Preview("SettingsView") {
    SettingsView()
        .modelContainer(for: [BottleneckEntry.self, ToolDevelopment.self], inMemory: true)
        .frame(width: 600, height: 700)
}
