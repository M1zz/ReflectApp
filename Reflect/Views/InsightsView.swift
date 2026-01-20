import SwiftUI
import SwiftData
import Charts

// MARK: - Dashboard View (주간 분석 대시보드)
struct DashboardView: View {
    @Query(sort: \BottleneckEntry.createdAt, order: .reverse) private var entries: [BottleneckEntry]
    @Query(sort: \ToolDevelopment.toolName) private var tools: [ToolDevelopment]

    @State private var selectedPeriod: TimePeriod = .week

    enum TimePeriod: String, CaseIterable {
        case week = "1주일"
        case month = "1개월"
        case all = "전체"

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return nil
            }
        }
    }

    private var filteredEntries: [BottleneckEntry] {
        guard let days = selectedPeriod.days else { return Array(entries) }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return entries.filter { $0.createdAt >= cutoff }
    }

    // 통계 계산
    private var totalWastedMinutes: Int {
        filteredEntries.reduce(0) { $0 + $1.wastedMinutes }
    }

    private var weeklyWastedMinutes: Int {
        filteredEntries.reduce(0) { $0 + $1.weeklyWastedMinutes }
    }

    private var averageAutomationScore: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        return Double(filteredEntries.reduce(0) { $0 + $1.automationScore }) / Double(filteredEntries.count)
    }

    // TOP 5 병목 지점 (ROI 순)
    private var topBottlenecks: [BottleneckEntry] {
        Array(filteredEntries.sorted { $0.roiScore > $1.roiScore }.prefix(5))
    }

    // 태그별 통계
    private var tagStats: [(tag: String, count: Int, wastedMinutes: Int)] {
        var stats: [String: (count: Int, wasted: Int)] = [:]
        for entry in filteredEntries {
            for tag in entry.tags {
                let current = stats[tag] ?? (0, 0)
                stats[tag] = (current.count + 1, current.wasted + entry.wastedMinutes)
            }
        }
        return stats.map { (tag: $0.key, count: $0.value.count, wastedMinutes: $0.value.wasted) }
            .sorted { $0.wastedMinutes > $1.wastedMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                headerSection

                // 기간 선택
                periodSelector

                // 핵심 지표
                statsGrid

                // 차트 섹션
                HStack(alignment: .top, spacing: 20) {
                    wastedTimeChart
                    tagDistributionChart
                }

                // TOP 5 병목 지점 & 도구 개발 우선순위
                HStack(alignment: .top, spacing: 20) {
                    topBottlenecksCard
                    toolPriorityCard
                }
            }
            .padding(24)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("분석 대시보드")
                .font(.title.bold())
                .foregroundStyle(.primary)

            Text("병목 지점을 분석하고 자동화 우선순위를 확인하세요")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.body.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color.blue : Color(.controlBackgroundColor))
                        .foregroundStyle(selectedPeriod == period ? .white : .secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "기록 수",
                value: "\(filteredEntries.count)",
                subtitle: "개",
                icon: "doc.text.fill",
                color: .blue
            )

            StatCard(
                title: "총 낭비 시간",
                value: BottleneckEntry.formatMinutes(totalWastedMinutes),
                subtitle: "",
                icon: "clock.badge.exclamationmark",
                color: .red
            )

            StatCard(
                title: "주간 낭비",
                value: BottleneckEntry.formatMinutes(weeklyWastedMinutes),
                subtitle: "예상",
                icon: "calendar.badge.clock",
                color: .orange
            )

            StatCard(
                title: "평균 도구화 점수",
                value: String(format: "%.1f", averageAutomationScore),
                subtitle: "/5",
                icon: "star.fill",
                color: .yellow
            )
        }
    }

    // MARK: - Wasted Time Chart
    private var wastedTimeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("일별 낭비 시간 추이", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(.primary)

            if filteredEntries.count >= 2 {
                let dailyData = calculateDailyWastedTime()

                Chart(dailyData, id: \.date) { item in
                    AreaMark(
                        x: .value("날짜", item.date),
                        y: .value("낭비 시간", item.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.5), Color.red.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("날짜", item.date),
                        y: .value("낭비 시간", item.minutes)
                    )
                    .foregroundStyle(Color.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("날짜", item.date),
                        y: .value("낭비 시간", item.minutes)
                    )
                    .foregroundStyle(Color.red)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.secondary.opacity(0.2))
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)분")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatShortDate(date))
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            } else {
                emptyChartPlaceholder
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tag Distribution Chart
    private var tagDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("태그별 낭비 시간", systemImage: "tag.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            if !tagStats.isEmpty {
                let topTags = Array(tagStats.prefix(5))

                Chart(topTags, id: \.tag) { item in
                    BarMark(
                        x: .value("낭비 시간", item.wastedMinutes),
                        y: .value("태그", item.tag)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .annotation(position: .trailing) {
                        Text("\(item.wastedMinutes)분")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let tag = value.as(String.self) {
                                Text("#\(tag)")
                                    .font(.body)
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                }
                .frame(height: 180)
            } else {
                emptyChartPlaceholder
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top Bottlenecks Card
    private var topBottlenecksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("TOP 5 병목 지점 (ROI 순)", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            if topBottlenecks.isEmpty {
                Text("아직 기록이 없습니다")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(Array(topBottlenecks.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        // 순위
                        Text("\(index + 1)")
                            .font(.body.bold())
                            .frame(width: 24, height: 24)
                            .background(rankColor(index))
                            .foregroundStyle(.white)
                            .clipShape(Circle())

                        // 정보
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.taskName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                Text(entry.automationEmoji)
                                Text("주 \(entry.weeklyFrequency)회")
                                    .font(.body)
                                    .foregroundStyle(.blue)
                                Text("+\(entry.wastedMinutes)분/회")
                                    .font(.body)
                                    .foregroundStyle(.red)
                            }
                        }

                        Spacer()

                        // ROI
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("ROI")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.0f", entry.roiScore))
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.purple)
                        }
                    }
                    .padding(.vertical, 8)

                    if index < topBottlenecks.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tool Priority Card
    private var toolPriorityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("도구 개발 우선순위", systemImage: "hammer.fill")
                .font(.headline)
                .foregroundStyle(.purple)

            if topBottlenecks.isEmpty {
                Text("병목 지점 데이터가 필요합니다")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                // ROI 기반 우선순위 제안
                ForEach(Array(topBottlenecks.prefix(3).enumerated()), id: \.element.id) { index, entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("우선순위 \(index + 1)")
                                .font(.body.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(rankColor(index).opacity(0.2))
                                .foregroundStyle(rankColor(index))
                                .clipShape(Capsule())

                            Spacer()

                            // 예상 절감 시간
                            Text("주 \(entry.weeklyWastedMinutes)분 절감 가능")
                                .font(.body)
                                .foregroundStyle(.green)
                        }

                        Text(entry.taskName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)

                        // 자동화 제안
                        Text(automationSuggestion(for: entry))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // ROI 설명
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("ROI = 도구화 점수 × 주간 낭비 시간")
                }
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary.opacity(0.5))
            Text("데이터가 부족합니다")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }

    private func calculateDailyWastedTime() -> [(date: Date, minutes: Int)] {
        let calendar = Calendar.current
        var dailyData: [Date: Int] = [:]

        for entry in filteredEntries {
            let day = calendar.startOfDay(for: entry.createdAt)
            dailyData[day, default: 0] += entry.wastedMinutes
        }

        return dailyData.map { (date: $0.key, minutes: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .orange
        case 1: return .gray
        case 2: return .brown
        default: return .blue
        }
    }

    private func automationSuggestion(for entry: BottleneckEntry) -> String {
        if entry.automationScore >= 4 {
            return "높은 자동화 가능성! 스크립트나 도구 개발을 권장합니다."
        } else if entry.automationScore >= 3 {
            return "부분 자동화 가능. 템플릿이나 체크리스트로 시작해보세요."
        } else {
            return "프로세스 개선이나 문서화를 먼저 고려해보세요."
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.primary)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(title)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [BottleneckEntry.self, ToolDevelopment.self], inMemory: true)
        .frame(width: 900, height: 800)
}
