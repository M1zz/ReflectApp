import SwiftUI
import Charts

// MARK: - Energy Trend Chart
struct EnergyTrendChart: View {
    let entries: [ReflectionEntry]
    
    var data: [(index: Int, energy: Int, date: Date)] {
        let withEnergy = entries.prefix(30).filter { $0.energyLevel > 0 }.reversed()
        return Array(withEnergy.enumerated().map { ($0.offset, $0.element.energyLevel, $0.element.date) })
    }
    
    var body: some View {
        if data.isEmpty {
            Text("에너지 데이터 없음").font(.caption).foregroundStyle(.tertiary)
        } else {
            Chart(data, id: \.index) { item in
                LineMark(
                    x: .value("Index", item.index),
                    y: .value("Energy", item.energy)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    .linearGradient(
                        colors: [.red, .orange, .green],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                
                AreaMark(
                    x: .value("Index", item.index),
                    y: .value("Energy", item.energy)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    .linearGradient(
                        colors: [.orange.opacity(0.2), .orange.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                PointMark(
                    x: .value("Index", item.index),
                    y: .value("Energy", item.energy)
                )
                .foregroundStyle(item.energy <= 3 ? .red : item.energy <= 6 ? .orange : .green)
                .symbolSize(30)
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(values: [0, 5, 10]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.tertiary)
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 160)
        }
    }
}

// MARK: - Tag Distribution Chart
struct TagDistributionChart: View {
    let data: [(String, Int)]
    
    var body: some View {
        if data.isEmpty {
            Text("태그 데이터 없음").font(.caption).foregroundStyle(.tertiary)
        } else {
            Chart(data.prefix(8), id: \.0) { item in
                BarMark(
                    x: .value("Count", item.1),
                    y: .value("Tag", item.0)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.orange, .orange.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(item.1)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text(value.as(String.self) ?? "")
                            .font(.system(size: 12))
                    }
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(min(data.count, 8)) * 36)
        }
    }
}

// MARK: - Emotion Pie Chart
struct EmotionDistributionChart: View {
    let data: [(String, Int)]
    
    var total: Int { data.reduce(0) { $0 + $1.1 } }
    
    var body: some View {
        if data.isEmpty {
            Text("감정 데이터 없음").font(.caption).foregroundStyle(.tertiary)
        } else {
            HStack(spacing: 20) {
                // Donut
                ZStack {
                    ForEach(segmentData.indices, id: \.self) { i in
                        let seg = segmentData[i]
                        Circle()
                            .trim(from: seg.start, to: seg.end)
                            .stroke(seg.color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(total)")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                        Text("총 기록")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(data.prefix(6), id: \.0) { emoji, count in
                        HStack(spacing: 8) {
                            Text(emoji).font(.system(size: 18))
                            Text("\(count)회")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                            
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.orange.opacity(0.3))
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(max(total, 1)))
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
    }
    
    struct Segment {
        let start: CGFloat
        let end: CGFloat
        let color: Color
    }
    
    var segmentData: [Segment] {
        let colors: [Color] = [.orange, .blue, .green, .purple, .red, .cyan, .pink, .yellow]
        var segments: [Segment] = []
        var current: CGFloat = 0
        
        for (i, item) in data.prefix(8).enumerated() {
            let fraction = CGFloat(item.1) / CGFloat(max(total, 1))
            let gap: CGFloat = 0.005
            segments.append(Segment(
                start: current + gap,
                end: current + fraction - gap,
                color: colors[i % colors.count]
            ))
            current += fraction
        }
        return segments
    }
}

// MARK: - Pattern Radar View
struct PatternRadarView: View {
    let patterns: [DiscoveredPattern]

    var categoryScores: [(String, Double)] {
        let types: [(PatternType, String)] = [
            (.recurringTheme, "반복 주제"),
            (.emotionPattern, "감정"),
            (.energyPattern, "에너지"),
            (.keywordPattern, "키워드"),
            (.questionPattern, "질문 응답"),
            (.timePattern, "시간대"),
        ]

        return types.map { type, label in
            let count = patterns.filter { $0.type == type && !$0.isResolved }.count
            let score = min(Double(count) / 3.0, 1.0)  // normalize to 0-1
            return (label, score)
        }
    }

    struct RadarPoint: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let label: String
    }

    private func calculateAngle(index: Int, count: Int) -> CGFloat {
        CGFloat(index) / CGFloat(count) * 2 * .pi - .pi / 2
    }

    private var pointsData: [RadarPoint] {
        let count = categoryScores.count
        return categoryScores.indices.map { i -> RadarPoint in
            let angle = calculateAngle(index: i, count: count)
            let score = categoryScores[i].1
            let r = score * 60.0
            let xPos = CoreGraphics.cos(angle) * r
            let yPos = CoreGraphics.sin(angle) * r
            return RadarPoint(id: i, x: xPos, y: yPos, label: "")
        }
    }

    private var labelsData: [RadarPoint] {
        let count = categoryScores.count
        return categoryScores.indices.map { i -> RadarPoint in
            let angle = calculateAngle(index: i, count: count)
            let r: CGFloat = 80.0
            let xPos = CoreGraphics.cos(angle) * r
            let yPos = CoreGraphics.sin(angle) * r
            let labelText = categoryScores[i].0
            return RadarPoint(id: i, x: xPos, y: yPos, label: labelText)
        }
    }

    var body: some View {
        if patterns.isEmpty {
            Text("패턴 데이터 없음").font(.caption).foregroundStyle(.tertiary)
        } else {
            ZStack {
                backgroundRings
                dataPolygon
                dataPoints
                dataLabels
            }
            .frame(width: 200, height: 200)
        }
    }

    private var backgroundRings: some View {
        ForEach(1...3, id: \.self) { ring in
            RadarPolygon(scores: Array(repeating: Double(ring) / 3.0, count: categoryScores.count))
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var dataPolygon: some View {
        Group {
            RadarPolygon(scores: categoryScores.map { $0.1 })
                .fill(.orange.opacity(0.15))

            RadarPolygon(scores: categoryScores.map { $0.1 })
                .stroke(.orange, lineWidth: 2)
        }
    }

    private var dataPoints: some View {
        ForEach(pointsData) { point in
            Circle()
                .fill(.orange)
                .frame(width: 8, height: 8)
                .offset(x: point.x, y: point.y)
        }
    }

    private var dataLabels: some View {
        ForEach(labelsData) { point in
            Text(point.label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .offset(x: point.x, y: point.y)
        }
    }
}

struct RadarPolygon: Shape {
    let scores: [Double]
    
    func path(in rect: CGRect) -> Path {
        guard scores.count >= 3 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.75
        
        var path = Path()
        for (i, score) in scores.enumerated() {
            let angle = CGFloat(i) / CGFloat(scores.count) * 2 * .pi - .pi / 2
            let r = CGFloat(score) * radius
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Weekly Heatmap
struct WeeklyHeatmap: View {
    let entries: [ReflectionEntry]
    
    var grid: [[Int]] {
        // 7 days x 4 weeks
        let cal = Calendar.current
        var result = Array(repeating: Array(repeating: 0, count: 7), count: 4)
        let today = cal.startOfDay(for: Date())
        
        for entry in entries {
            let entryDay = cal.startOfDay(for: entry.date)
            let daysAgo = cal.dateComponents([.day], from: entryDay, to: today).day ?? 0
            if daysAgo < 28 {
                let week = daysAgo / 7
                let day = daysAgo % 7
                if week < 4 && day < 7 {
                    result[week][6 - day] += 1
                }
            }
        }
        return result
    }
    
    let dayLabels = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("").frame(width: 20)
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            ForEach(0..<4, id: \.self) { week in
                HStack(spacing: 4) {
                    Text("\(week == 0 ? "이번주" : "\(week)주전")")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                        .frame(width: 30, alignment: .trailing)
                    
                    ForEach(0..<7, id: \.self) { day in
                        let count = grid[week][day]
                        RoundedRectangle(cornerRadius: 3)
                            .fill(count == 0 ? Color.primary.opacity(0.04) : Color.orange.opacity(Double(min(count, 3)) / 3.0 * 0.7 + 0.15))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
}
