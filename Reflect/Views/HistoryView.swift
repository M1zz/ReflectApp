import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]
    
    @State private var selectedReflection: Reflection?
    @State private var searchText: String = ""
    @State private var selectedMonth: Date = Date()
    
    private var filteredReflections: [Reflection] {
        let calendar = Calendar.current
        return reflections.filter { reflection in
            let sameMonth = calendar.isDate(reflection.date, equalTo: selectedMonth, toGranularity: .month)
            let matchesSearch = searchText.isEmpty || 
                reflection.wentWell.localizedCaseInsensitiveContains(searchText) ||
                reflection.couldImprove.localizedCaseInsensitiveContains(searchText) ||
                reflection.nextAction.localizedCaseInsensitiveContains(searchText) ||
                reflection.learnings.localizedCaseInsensitiveContains(searchText)
            return sameMonth && matchesSearch
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Calendar & List
            VStack(spacing: 0) {
                // Month Navigator
                monthNavigator
                
                // Calendar Grid
                calendarGrid
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Search
                searchBar
                
                // Reflection List
                reflectionList
            }
            .frame(width: 340)
            .background(Color.white.opacity(0.02))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Right: Detail
            if let selected = selectedReflection {
                ReflectionDetailView(reflection: selected)
            } else {
                emptyDetailView
            }
        }
    }
    
    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.05)))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(monthYearString)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                withAnimation {
                    selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.05)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let calendar = Calendar.current
        let days = generateDaysInMonth()
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        
        return VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let hasReflection = reflections.contains { calendar.isDateInToday($0.date) ? calendar.isDateInToday(date) : calendar.isDate($0.date, inSameDayAs: date) }
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = selectedReflection.map { calendar.isDate($0.date, inSameDayAs: date) } ?? false
                        
                        Button {
                            if let reflection = reflections.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                                selectedReflection = reflection
                            }
                        } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: hasReflection ? .semibold : .regular))
                                .foregroundColor(
                                    isSelected ? Color(hex: "1a1a2e") :
                                    isToday ? Color(hex: "818cf8") :
                                    hasReflection ? .white :
                                    .white.opacity(0.3)
                                )
                                .frame(width: 36, height: 36)
                                .background(
                                    Group {
                                        if isSelected {
                                            Circle().fill(Color(hex: "818cf8"))
                                        } else if hasReflection {
                                            Circle().fill(Color.white.opacity(0.1))
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
            
            TextField("회고 검색...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Reflection List
    private var reflectionList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredReflections) { reflection in
                    ReflectionRowView(
                        reflection: reflection,
                        isSelected: selectedReflection?.id == reflection.id
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedReflection = reflection
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Empty Detail
    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))
            
            Text("회고를 선택하세요")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            
            Text("왼쪽 목록에서 회고를 클릭하면\n상세 내용을 볼 수 있어요")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: selectedMonth)
    }
    
    private func generateDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var current = monthFirstWeek.start
        
        while current < monthInterval.end || days.count % 7 != 0 {
            if current >= monthInterval.start && current < monthInterval.end {
                days.append(current)
            } else {
                days.append(nil)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return days
    }
}

// MARK: - Row View
struct ReflectionRowView: View {
    let reflection: Reflection
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reflection.formattedDate)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: 4) {
                    moodIndicator
                    energyIndicator
                }
            }
            
            if !reflection.wentWell.isEmpty {
                Text(reflection.wentWell)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color(hex: "818cf8").opacity(0.2) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color(hex: "818cf8").opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var moodIndicator: some View {
        Circle()
            .fill(moodColor)
            .frame(width: 8, height: 8)
    }
    
    private var energyIndicator: some View {
        Circle()
            .fill(energyColor)
            .frame(width: 8, height: 8)
    }
    
    private var moodColor: Color {
        switch reflection.moodScore {
        case 1...2: return Color(hex: "ef4444")
        case 3: return Color(hex: "fbbf24")
        case 4...5: return Color(hex: "4ade80")
        default: return Color(hex: "fbbf24")
        }
    }
    
    private var energyColor: Color {
        switch reflection.energyLevel {
        case 1...2: return Color(hex: "94a3b8")
        case 3: return Color(hex: "fbbf24")
        case 4...5: return Color(hex: "818cf8")
        default: return Color(hex: "fbbf24")
        }
    }
}

// MARK: - Detail View
struct ReflectionDetailView: View {
    let reflection: Reflection
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(reflection.formattedDate)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        Label("기분 \(reflection.moodScore)/5", systemImage: "face.smiling")
                            .foregroundColor(Color(hex: "818cf8"))
                        Label("에너지 \(reflection.energyLevel)/5", systemImage: "bolt.fill")
                            .foregroundColor(Color(hex: "fbbf24"))
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .padding(.bottom, 8)
                
                // Content sections
                if !reflection.wentWell.isEmpty {
                    detailSection(
                        title: "잘한 것",
                        icon: "checkmark.circle.fill",
                        color: Color(hex: "4ade80"),
                        content: reflection.wentWell
                    )
                }
                
                if !reflection.couldImprove.isEmpty {
                    detailSection(
                        title: "개선할 점",
                        icon: "arrow.up.circle.fill",
                        color: Color(hex: "fbbf24"),
                        content: reflection.couldImprove
                    )
                }
                
                if !reflection.nextAction.isEmpty {
                    detailSection(
                        title: "다음 액션",
                        icon: "bolt.circle.fill",
                        color: Color(hex: "818cf8"),
                        content: reflection.nextAction
                    )
                }
                
                if !reflection.gratitude.isEmpty {
                    detailSection(
                        title: "감사한 것",
                        icon: "heart.circle.fill",
                        color: Color(hex: "f472b6"),
                        content: reflection.gratitude
                    )
                }
                
                if !reflection.learnings.isEmpty {
                    detailSection(
                        title: "배운 것",
                        icon: "lightbulb.fill",
                        color: Color(hex: "38bdf8"),
                        content: reflection.learnings
                    )
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func detailSection(title: String, icon: String, color: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text(content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: Reflection.self, inMemory: true)
        .frame(width: 900, height: 700)
}
