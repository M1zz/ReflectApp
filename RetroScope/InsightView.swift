import SwiftUI
import Charts
import UniformTypeIdentifiers

struct InsightDashboardView: View {
    @Environment(ReflectionStore.self) var store
    @State private var showExportSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("인사이트")
                            .font(.system(size: 26, weight: .bold))
                        Text("회고 데이터를 한눈에 파악하세요")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.top, 32)
                
                if store.entries.isEmpty {
                    emptyState
                } else {
                    // Stat cards
                    statCards
                    
                    // Charts grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        chartCard("에너지 추이") {
                            EnergyTrendChart(entries: store.entries)
                        }
                        
                        chartCard("패턴 레이더") {
                            PatternRadarView(patterns: store.patterns)
                                .frame(height: 200)
                        }
                        
                        chartCard("영역별 회고 분포") {
                            TagDistributionChart(data: store.tagDistribution)
                        }
                        
                        chartCard("감정 분포") {
                            EmotionDistributionChart(data: store.emotionDistribution)
                        }
                    }
                    
                    // Heatmap
                    chartCard("최근 4주 회고 빈도") {
                        WeeklyHeatmap(entries: store.entries)
                    }
                    
                    // Question response analysis
                    if !store.entries.isEmpty {
                        chartCard("질문별 응답률") {
                            questionResponseChart
                        }
                    }
                    
                    // Data management
                    Divider().padding(.top, 16)
                    dataManagement
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Stat Cards
    var statCards: some View {
        HStack(spacing: 12) {
            statCard(value: "\(store.entries.count)", label: "총 회고 수", color: .primary)
            statCard(
                value: "\(store.activePatterns.count)",
                label: "활성 패턴",
                color: store.activePatterns.count > 0 ? .red : .green
            )
            statCard(
                value: store.averageEnergy > 0 ? String(format: "%.1f", store.averageEnergy) : "—",
                label: "평균 에너지",
                color: .orange
            )
            statCard(value: "\(store.streakDays)", label: "연속 회고일", color: .blue)
        }
    }
    
    func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Chart Card
    func chartCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Question Response Chart
    var questionResponseChart: some View {
        let questionStats = computeQuestionStats()
        
        return VStack(spacing: 8) {
            ForEach(questionStats, id: \.id) { stat in
                HStack(spacing: 10) {
                    Text(stat.emoji)
                        .font(.system(size: 16))
                    
                    Text(stat.shortName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.primary.opacity(0.04))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.orange.opacity(0.6))
                                .frame(width: geo.size.width * stat.rate)
                        }
                    }
                    .frame(height: 12)
                    
                    Text("\(Int(stat.rate * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }
    
    struct QuestionStat {
        let id: String
        let emoji: String
        let shortName: String
        let rate: CGFloat
    }
    
    func computeQuestionStats() -> [QuestionStat] {
        let total = store.entries.count
        guard total > 0 else { return [] }
        
        return reflectionQuestions.compactMap { q in
            let answered = store.entries.filter { entry in
                entry.answers.contains { $0.questionId == q.id && !$0.answer.isEmpty }
            }.count
            
            guard answered > 0 else { return nil }
            
            let shortName = q.question.components(separatedBy: "\n").first?
                .replacingOccurrences(of: "오늘 하루 중 ", with: "")
                .replacingOccurrences(of: "있었나요?", with: "")
                .replacingOccurrences(of: "있나요?", with: "")
                .prefix(12)
            
            return QuestionStat(
                id: q.id,
                emoji: q.emoji,
                shortName: String(shortName ?? ""),
                rate: CGFloat(answered) / CGFloat(total)
            )
        }
        .sorted { $0.rate > $1.rate }
    }
    
    // MARK: - Data Management
    var dataManagement: some View {
        HStack(spacing: 12) {
            Spacer()
            
            Button {
                exportData()
            } label: {
                Label("데이터 내보내기", systemImage: "square.and.arrow.up")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            
            Button {
                importData()
            } label: {
                Label("데이터 가져오기", systemImage: "square.and.arrow.down")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            
            Button {
                clearAll()
            } label: {
                Label("전체 삭제", systemImage: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .tint(.red)
            
            Spacer()
        }
        .padding(.bottom, 20)
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("데이터가 부족합니다")
                .font(.system(size: 17, weight: .semibold))
            Text("회고를 작성할수록\n더 풍부한 인사이트를 볼 수 있습니다")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(60)
    }
    
    // MARK: - Data Actions
    func exportData() {
        guard let data = store.exportJSON() else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "retroscope_\(dateString).json"
        
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
    
    func importData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.urls.first {
            if let data = try? Data(contentsOf: url) {
                let count = store.importJSON(from: data)
                // Could show toast
            }
        }
    }
    
    func clearAll() {
        let alert = NSAlert()
        alert.messageText = "전체 데이터 삭제"
        alert.informativeText = "모든 회고와 패턴 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "삭제")
        alert.addButton(withTitle: "취소")
        
        if alert.runModal() == .alertFirstButtonReturn {
            UserDefaults.standard.removeObject(forKey: "retroscope_entries")
            UserDefaults.standard.removeObject(forKey: "retroscope_patterns")
            store.entries = []
            store.patterns = []
        }
    }
    
    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
