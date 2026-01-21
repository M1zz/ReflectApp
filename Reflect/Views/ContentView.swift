import SwiftUI
import SwiftData

// MARK: - Navigation Items
enum NavigationItem: String, CaseIterable, Identifiable {
    case today = "오늘 기록"
    case history = "전체 기록"
    case dashboard = "대시보드"
    case tools = "도구 트래커"
    case settings = "설정"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today: return "plus.circle.fill"
        case .history: return "list.bullet.rectangle"
        case .dashboard: return "chart.bar.xaxis"
        case .tools: return "hammer.fill"
        case .settings: return "gearshape"
        }
    }

    var color: Color {
        switch self {
        case .today: return .green
        case .history: return .blue
        case .dashboard: return .orange
        case .tools: return .purple
        case .settings: return .gray
        }
    }
}

// MARK: - Content View (3단 레이아웃)
struct ContentView: View {
    @State private var selectedItem: NavigationItem = .today
    @State private var selectedEntry: BottleneckEntry?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BottleneckEntry.createdAt, order: .reverse) private var entries: [BottleneckEntry]

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 왼쪽: 사이드바
            SidebarView(selectedItem: $selectedItem)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } content: {
            // 중앙: 메인 콘텐츠
            ZStack {
                backgroundGradient

                switch selectedItem {
                case .today:
                    DailyLogView(selectedEntry: $selectedEntry)
                case .history:
                    HistoryListView(selectedEntry: $selectedEntry)
                case .dashboard:
                    DashboardView()
                case .tools:
                    ToolTrackerView()
                case .settings:
                    SettingsView()
                }
            }
            .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: 700)
        } detail: {
            // 오른쪽: 인스펙터 (상세/통계)
            ZStack {
                backgroundGradient

                if selectedItem == .dashboard || selectedItem == .settings || selectedItem == .tools {
                    // 대시보드, 설정, 도구 트래커는 인스펙터 불필요
                    EmptyInspectorView()
                } else if let entry = selectedEntry {
                    EntryInspectorView(entry: entry)
                } else {
                    QuickStatsView(entries: entries)
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        }
        .navigationSplitViewStyle(.balanced)
        .onReceive(NotificationCenter.default.publisher(for: .addNewEntry)) { _ in
            selectedItem = .today
        }
        .onReceive(NotificationCenter.default.publisher(for: .showDashboard)) { _ in
            selectedItem = .dashboard
        }
    }

    private var backgroundGradient: some View {
        Color(.windowBackgroundColor)
            .ignoresSafeArea()
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Binding var selectedItem: NavigationItem
    @Query(sort: \BottleneckEntry.createdAt, order: .reverse) private var entries: [BottleneckEntry]

    private var todayCount: Int {
        entries.filter { $0.isToday }.count
    }

    private var weeklyWastedTime: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return entries
            .filter { $0.createdAt >= weekAgo }
            .reduce(0) { $0 + $1.wastedMinutes }
    }

    var body: some View {
        List(selection: $selectedItem) {
            Section {
                ForEach(NavigationItem.allCases) { item in
                    NavigationLink(value: item) {
                        HStack(spacing: 10) {
                            Image(systemName: item.icon)
                                .foregroundStyle(item.color)
                                .frame(width: 20)

                            Text(item.rawValue)

                            Spacer()

                            // 뱃지 표시
                            if item == .today && todayCount > 0 {
                                Text("\(todayCount)")
                                    .font(.body)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.3))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("돌아보기")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }

                    // 주간 낭비 시간 미니 통계
                    if weeklyWastedTime > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.body)
                            Text("이번 주 \(BottleneckEntry.formatMinutes(weeklyWastedTime)) 낭비")
                                .font(.body)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Empty Inspector View
struct EmptyInspectorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("상세 정보 없음")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Quick Stats View (인스펙터 기본 뷰)
struct QuickStatsView: View {
    let entries: [BottleneckEntry]

    private var weekEntries: [BottleneckEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return entries.filter { $0.createdAt >= weekAgo }
    }

    private var totalWastedMinutes: Int {
        weekEntries.reduce(0) { $0 + $1.weeklyWastedMinutes }
    }

    private var topBottlenecks: [BottleneckEntry] {
        Array(weekEntries.sorted { $0.roiScore > $1.roiScore }.prefix(3))
    }

    private var allTags: [String: Int] {
        var tagCounts: [String: Int] = [:]
        for entry in weekEntries {
            for tag in entry.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        return tagCounts
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                Text("빠른 통계")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                // 주간 요약 카드
                VStack(alignment: .leading, spacing: 12) {
                    Label("이번 주 요약", systemImage: "calendar")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 16) {
                        StatMiniCard(
                            title: "기록 수",
                            value: "\(weekEntries.count)",
                            icon: "doc.text",
                            color: .blue
                        )

                        StatMiniCard(
                            title: "낭비 시간",
                            value: BottleneckEntry.formatMinutes(totalWastedMinutes),
                            icon: "clock",
                            color: .red
                        )
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // TOP 3 병목 지점
                if !topBottlenecks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("TOP 3 병목 지점", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        ForEach(Array(topBottlenecks.enumerated()), id: \.element.id) { index, entry in
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.body.bold())
                                    .frame(width: 20, height: 20)
                                    .background(Color.orange.opacity(0.3))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.taskName)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text("\(entry.automationEmoji) 도구화 \(entry.automationScore)점")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("+\(entry.wastedMinutes)분")
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(.red)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 자주 사용된 태그
                if !allTags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("자주 사용된 태그", systemImage: "tag")
                            .font(.headline)
                            .foregroundStyle(.purple)

                        FlowLayout(spacing: 8) {
                            ForEach(allTags.sorted(by: { $0.value > $1.value }).prefix(6), id: \.key) { tag, count in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                        .font(.body)
                                    Text("\(count)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.purple.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Stat Mini Card
struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.body)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Entry Inspector View
struct EntryInspectorView: View {
    let entry: BottleneckEntry
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("상세 정보")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        Text(entry.formattedDate)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }

                Divider()

                // 작업 정보
                VStack(alignment: .leading, spacing: 16) {
                    // 작업명
                    InfoRow(label: "작업명", value: entry.taskName, icon: "doc.text")

                    // 시간 정보
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("예상", systemImage: "clock")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text(BottleneckEntry.formatMinutes(entry.estimatedMinutes))
                                .font(.headline)
                                .foregroundStyle(.green)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Label("실제", systemImage: "clock.fill")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text(BottleneckEntry.formatMinutes(entry.actualMinutes))
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Label("낭비", systemImage: "exclamationmark.circle")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text("+\(BottleneckEntry.formatMinutes(entry.wastedMinutes))")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // 지연 원인
                    if !entry.delayReason.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("지연 원인", systemImage: "exclamationmark.bubble")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text(entry.delayReason)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }

                    // 반복 빈도 & 도구화 점수
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("주간 반복", systemImage: "repeat")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text("\(entry.weeklyFrequency)회")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Label("도구화 가능성", systemImage: "hammer")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= entry.automationScore ? "star.fill" : "star")
                                        .font(.body)
                                        .foregroundStyle(i <= entry.automationScore ? .yellow : .gray)
                                }
                            }
                        }
                    }

                    // ROI 점수
                    VStack(alignment: .leading, spacing: 6) {
                        Label("ROI 점수", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(String(format: "%.1f", entry.roiScore))
                                .font(.title.bold().monospacedDigit())
                                .foregroundStyle(.purple)

                            Text("(도구화 점수 × 주간 낭비 시간)")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // 태그
                    if !entry.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("태그", systemImage: "tag")
                                .font(.body)
                                .foregroundStyle(.secondary)

                            FlowLayout(spacing: 6) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.body)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // 메모
                    if !entry.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("메모", systemImage: "note.text")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text(entry.notes)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Spacer()

                // 삭제 버튼
                Button(role: .destructive) {
                    modelContext.delete(entry)
                } label: {
                    Label("삭제", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .sheet(isPresented: $isEditing) {
            EditEntrySheet(entry: entry)
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.body)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Flow Layout (태그 표시용)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = max(totalHeight, currentY + size.height)
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BottleneckEntry.self, ToolDevelopment.self, QuestionLog.self, Goal.self], inMemory: true)
}
