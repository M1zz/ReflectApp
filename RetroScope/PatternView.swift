import SwiftUI

struct PatternListView: View {
    @Environment(ReflectionStore.self) var store
    @State private var showResolved = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("발견된 패턴")
                            .font(.system(size: 26, weight: .bold))
                        Text("회고 데이터에서 자동으로 발견된 반복 패턴입니다")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !store.patterns.isEmpty {
                        Text("\(store.activePatterns.count)개 활성")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.orange.opacity(0.15)))
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.top, 32)
                
                if store.patterns.isEmpty {
                    emptyState
                } else {
                    // Pattern severity overview
                    patternOverviewBar
                    
                    // Active patterns
                    ForEach(store.activePatterns) { pattern in
                        PatternCard(pattern: pattern) {
                            store.resolvePattern(pattern)
                        } onDismiss: {
                            store.dismissPattern(pattern)
                        }
                    }
                    
                    // Resolved
                    if !store.resolvedPatterns.isEmpty {
                        DisclosureGroup(isExpanded: $showResolved) {
                            ForEach(store.resolvedPatterns) { pattern in
                                PatternCard(pattern: pattern, isResolved: true) {} onDismiss: {
                                    store.dismissPattern(pattern)
                                }
                            }
                        } label: {
                            Text("인지 완료된 패턴 (\(store.resolvedPatterns.count))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Overview Bar
    var patternOverviewBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                overviewStat(count: store.activePatterns.filter { $0.severity == .high }.count, label: "주의", color: .red)
                overviewStat(count: store.activePatterns.filter { $0.severity == .mid }.count, label: "관찰", color: .orange)
                overviewStat(count: store.activePatterns.filter { $0.severity == .low }.count, label: "참고", color: .blue)
                overviewStat(count: store.activePatterns.filter { $0.severity == .positive }.count, label: "강점", color: .green)
            }
            
            // Severity bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    let total = max(store.activePatterns.count, 1)
                    let high = store.activePatterns.filter { $0.severity == .high }.count
                    let mid = store.activePatterns.filter { $0.severity == .mid }.count
                    let low = store.activePatterns.filter { $0.severity == .low }.count
                    let pos = store.activePatterns.filter { $0.severity == .positive }.count
                    
                    if high > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.red)
                            .frame(width: geo.size.width * CGFloat(high) / CGFloat(total))
                    }
                    if mid > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.orange)
                            .frame(width: geo.size.width * CGFloat(mid) / CGFloat(total))
                    }
                    if low > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.blue)
                            .frame(width: geo.size.width * CGFloat(low) / CGFloat(total))
                    }
                    if pos > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.green)
                            .frame(width: geo.size.width * CGFloat(pos) / CGFloat(total))
                    }
                }
            }
            .frame(height: 6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    func overviewStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(count > 0 ? color : .secondary.opacity(0.3))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("아직 발견된 패턴이 없습니다")
                .font(.system(size: 17, weight: .semibold))
            Text("회고를 3개 이상 작성하면\n패턴 분석이 시작됩니다")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(60)
    }
}

// MARK: - Pattern Card
struct PatternCard: View {
    let pattern: DiscoveredPattern
    var isResolved: Bool = false
    var onResolve: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top: name + severity
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(pattern.severity.color)
                        .frame(width: 8, height: 8)
                    Text(pattern.name)
                        .font(.system(size: 16, weight: .bold))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(pattern.frequency)회 발견")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                        .foregroundStyle(.secondary)
                    
                    Text(pattern.severity.label)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(pattern.severity.color.opacity(0.12)))
                        .foregroundStyle(pattern.severity.color)
                }
            }
            
            // Description
            Text(pattern.description)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
            
            // ⭐️ Causal Analysis - 원인과 증상
            if let causes = pattern.possibleCauses, !causes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("🔍")
                            .font(.system(size: 14))
                        Text("가능한 원인")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(causes, id: \.self) { cause in
                            HStack(spacing: 8) {
                                Text("→")
                                    .foregroundStyle(.red.opacity(0.6))
                                    .font(.system(size: 12, weight: .bold))
                                Text(cause)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                )
            }

            if let symptoms = pattern.symptoms, !symptoms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("⚠️")
                            .font(.system(size: 14))
                        Text("관찰된 증상")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(symptoms, id: \.self) { symptom in
                            HStack(spacing: 8) {
                                Text("•")
                                    .foregroundStyle(.orange.opacity(0.6))
                                    .font(.system(size: 14, weight: .bold))
                                Text(symptom)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
            }

            // Evidence
            if !pattern.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("관련 회고")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .tracking(1)

                    ForEach(pattern.evidence.indices, id: \.self) { i in
                        let ev = pattern.evidence[i]
                        HStack(spacing: 10) {
                            Text(formatDate(ev.date))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(width: 50, alignment: .trailing)

                            Text(ev.excerpt)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        if i < pattern.evidence.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.03))
                )
            }

            // Insight
            HStack(alignment: .top, spacing: 8) {
                Text("💡")
                    .font(.system(size: 16))
                Text(pattern.insight)
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                    .lineSpacing(4)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.15), lineWidth: 1)
            )
            
            // Actions
            if !isResolved {
                HStack(spacing: 8) {
                    Button {
                        withAnimation { onResolve() }
                    } label: {
                        Label("인지 완료", systemImage: "checkmark")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    
                    Button {
                        withAnimation { onDismiss() }
                    } label: {
                        Text("무시")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(24)
        .opacity(isResolved ? 0.5 : 1)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(pattern.severity.color)
                .frame(width: 3)
                .padding(.vertical, 12)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}
