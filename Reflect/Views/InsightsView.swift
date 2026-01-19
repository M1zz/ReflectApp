import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]
    
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "이번 주"
        case month = "이번 달"
        case all = "전체"
    }
    
    private var filteredReflections: [Reflection] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return reflections.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return reflections.filter { $0.date >= monthAgo }
        case .all:
            return reflections
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Period selector
                periodSelector
                
                // Stats Grid
                statsGrid
                
                // Charts
                HStack(alignment: .top, spacing: 24) {
                    moodChart
                    energyChart
                }
                
                // Patterns & Insights
                HStack(alignment: .top, spacing: 24) {
                    patternsCard
                    actionsCard
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("나의 성장 인사이트")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("회고 데이터를 분석해서 패턴을 발견해요")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? Color(hex: "1a1a2e") : .white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? Color(hex: "818cf8") : Color.white.opacity(0.05))
                        )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        HStack(spacing: 20) {
            statCard(
                title: "총 회고",
                value: "\(filteredReflections.count)",
                subtitle: "회",
                icon: "doc.text.fill",
                color: Color(hex: "818cf8")
            )
            
            statCard(
                title: "평균 기분",
                value: String(format: "%.1f", averageMood),
                subtitle: "/5",
                icon: "face.smiling.fill",
                color: Color(hex: "f472b6")
            )
            
            statCard(
                title: "평균 에너지",
                value: String(format: "%.1f", averageEnergy),
                subtitle: "/5",
                icon: "bolt.fill",
                color: Color(hex: "fbbf24")
            )
            
            statCard(
                title: "완료율",
                value: String(format: "%.0f", completionRate * 100),
                subtitle: "%",
                icon: "checkmark.circle.fill",
                color: Color(hex: "4ade80")
            )
        }
    }
    
    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Mood Chart
    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "face.smiling.fill")
                    .foregroundColor(Color(hex: "f472b6"))
                Text("기분 추이")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            if filteredReflections.count >= 2 {
                chartView(
                    data: filteredReflections.reversed().map { Double($0.moodScore) },
                    color: Color(hex: "f472b6")
                )
            } else {
                emptyChartPlaceholder
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Energy Chart
    private var energyChart: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(hex: "fbbf24"))
                Text("에너지 추이")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            if filteredReflections.count >= 2 {
                chartView(
                    data: filteredReflections.reversed().map { Double($0.energyLevel) },
                    color: Color(hex: "fbbf24")
                )
            } else {
                emptyChartPlaceholder
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func chartView(data: [Double], color: Color) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxValue: Double = 5
            let minValue: Double = 1
            let range = maxValue - minValue
            
            ZStack {
                // Grid lines
                ForEach(1...5, id: \.self) { i in
                    let y = height - (CGFloat(i - 1) / CGFloat(range)) * height
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
                
                // Line chart
                Path { path in
                    guard data.count > 1 else { return }
                    
                    let stepX = width / CGFloat(data.count - 1)
                    
                    for (index, value) in data.enumerated() {
                        let x = stepX * CGFloat(index)
                        let y = height - ((value - minValue) / range) * height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Data points
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    let stepX = width / CGFloat(data.count - 1)
                    let x = stepX * CGFloat(index)
                    let y = height - ((value - minValue) / range) * height
                    
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .frame(height: 120)
    }
    
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundColor(.white.opacity(0.2))
            Text("데이터가 더 필요해요")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Patterns Card
    private var patternsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(Color(hex: "818cf8"))
                Text("발견된 패턴")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                if averageEnergy > 3.5 {
                    patternItem(
                        emoji: "⚡️",
                        text: "에너지가 높은 날이 많아요! 좋은 컨디션을 유지하고 있네요."
                    )
                }
                
                if averageMood > 3.5 {
                    patternItem(
                        emoji: "😊",
                        text: "전반적으로 긍정적인 기분을 유지하고 있어요."
                    )
                }
                
                if completionRate > 0.8 {
                    patternItem(
                        emoji: "🎯",
                        text: "회고 완료율이 높아요! 꾸준함이 빛나고 있네요."
                    )
                }
                
                if filteredReflections.isEmpty {
                    Text("회고 데이터가 쌓이면 패턴을 분석해드릴게요")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func patternItem(emoji: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title3)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
    }
    
    // MARK: - Actions Card
    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "fbbf24"))
                Text("최근 액션 아이템")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                let recentActions = filteredReflections
                    .filter { !$0.nextAction.isEmpty }
                    .prefix(5)
                
                if recentActions.isEmpty {
                    Text("아직 등록된 액션이 없어요")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    ForEach(Array(recentActions), id: \.id) { reflection in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(Color(hex: "818cf8"))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reflection.nextAction)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                Text(reflection.shortDate)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    private var averageMood: Double {
        guard !filteredReflections.isEmpty else { return 0 }
        let total = filteredReflections.reduce(0) { $0 + $1.moodScore }
        return Double(total) / Double(filteredReflections.count)
    }
    
    private var averageEnergy: Double {
        guard !filteredReflections.isEmpty else { return 0 }
        let total = filteredReflections.reduce(0) { $0 + $1.energyLevel }
        return Double(total) / Double(filteredReflections.count)
    }
    
    private var completionRate: Double {
        guard !filteredReflections.isEmpty else { return 0 }
        let completed = filteredReflections.filter { $0.isCompleted }.count
        return Double(completed) / Double(filteredReflections.count)
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: Reflection.self, inMemory: true)
        .frame(width: 900, height: 800)
}
