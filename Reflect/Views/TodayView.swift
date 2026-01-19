import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]
    
    @State private var wentWell: String = ""
    @State private var couldImprove: String = ""
    @State private var nextAction: String = ""
    @State private var gratitude: String = ""
    @State private var learnings: String = ""
    @State private var energyLevel: Int = 3
    @State private var moodScore: Int = 3
    @State private var showingSavedAnimation: Bool = false
    @State private var currentStreak: Int = 0
    
    private var todayReflection: Reflection? {
        reflections.first { Calendar.current.isDateInToday($0.date) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Main content
                HStack(alignment: .top, spacing: 24) {
                    // Left column - Main reflection
                    VStack(spacing: 20) {
                        reflectionCard(
                            title: "오늘 잘한 것",
                            subtitle: "What went well",
                            icon: "checkmark.circle.fill",
                            iconColor: Color(hex: "4ade80"),
                            text: $wentWell,
                            placeholder: "오늘 잘 해낸 일, 성취, 긍정적인 경험을 적어보세요..."
                        )
                        
                        reflectionCard(
                            title: "개선할 점",
                            subtitle: "Even better if",
                            icon: "arrow.up.circle.fill",
                            iconColor: Color(hex: "fbbf24"),
                            text: $couldImprove,
                            placeholder: "다음에 더 잘할 수 있는 점, 아쉬웠던 부분..."
                        )
                        
                        reflectionCard(
                            title: "내일의 액션",
                            subtitle: "Next action",
                            icon: "bolt.circle.fill",
                            iconColor: Color(hex: "818cf8"),
                            text: $nextAction,
                            placeholder: "내일 실행할 구체적인 행동 하나..."
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right column - Secondary
                    VStack(spacing: 20) {
                        // Energy & Mood
                        moodEnergyCard
                        
                        reflectionCard(
                            title: "감사한 것",
                            subtitle: "Gratitude",
                            icon: "heart.circle.fill",
                            iconColor: Color(hex: "f472b6"),
                            text: $gratitude,
                            placeholder: "오늘 감사했던 순간이나 사람..."
                        )
                        
                        reflectionCard(
                            title: "오늘 배운 것",
                            subtitle: "Learnings",
                            icon: "lightbulb.fill",
                            iconColor: Color(hex: "38bdf8"),
                            text: $learnings,
                            placeholder: "새롭게 알게 된 것, 인사이트..."
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Save button
                saveButton
            }
            .padding(40)
        }
        .onAppear {
            loadTodayData()
            calculateStreak()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(formattedToday)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(greetingMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Streak badge
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "f97316"), Color(hex: "ef4444")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentStreak)일")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("연속 회고")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Reflection Card
    private func reflectionCard(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            TextEditor(text: text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    Group {
                        if text.wrappedValue.isEmpty {
                            Text(placeholder)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.25))
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Mood & Energy Card
    private var moodEnergyCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Energy Level
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(Color(hex: "fbbf24"))
                    Text("에너지 레벨")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(energyEmoji)
                        .font(.title2)
                }
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                energyLevel = level
                            }
                        } label: {
                            Circle()
                                .fill(level <= energyLevel ? 
                                      Color(hex: "fbbf24") : 
                                      Color.white.opacity(0.1))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("\(level)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(level <= energyLevel ? 
                                                        Color(hex: "1a1a2e") : 
                                                        Color.white.opacity(0.4))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Mood Score
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "face.smiling.fill")
                        .foregroundColor(Color(hex: "818cf8"))
                    Text("오늘의 기분")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(moodEmoji)
                        .font(.title2)
                }
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                moodScore = level
                            }
                        } label: {
                            Circle()
                                .fill(level <= moodScore ? 
                                      Color(hex: "818cf8") : 
                                      Color.white.opacity(0.1))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("\(level)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(level <= moodScore ? 
                                                        Color(hex: "1a1a2e") : 
                                                        Color.white.opacity(0.4))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveReflection()
        } label: {
            HStack(spacing: 12) {
                if showingSavedAnimation {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("저장됨!")
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.title3)
                    Text("오늘의 회고 저장하기")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: 300)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        showingSavedAnimation ?
                        LinearGradient(
                            colors: [Color(hex: "22c55e"), Color(hex: "16a34a")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
    }
    
    // MARK: - Helpers
    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "좋은 아침이에요 ☀️ 오늘 하루를 시작해볼까요?"
        case 12..<17: return "오후도 힘내세요 💪 잠시 멈추고 돌아보는 시간"
        case 17..<21: return "하루를 마무리하며 ✨ 오늘을 돌아봐요"
        default: return "늦은 시간까지 수고했어요 🌙"
        }
    }
    
    private var energyEmoji: String {
        switch energyLevel {
        case 1: return "😴"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "⚡️"
        default: return "🙂"
        }
    }
    
    private var moodEmoji: String {
        switch moodScore {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "🥰"
        default: return "😐"
        }
    }
    
    private func loadTodayData() {
        if let today = todayReflection {
            wentWell = today.wentWell
            couldImprove = today.couldImprove
            nextAction = today.nextAction
            gratitude = today.gratitude
            learnings = today.learnings
            energyLevel = today.energyLevel
            moodScore = today.moodScore
        }
    }
    
    private func calculateStreak() {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // Check if today has a reflection
        let hasToday = reflections.contains { calendar.isDate($0.date, inSameDayAs: checkDate) && $0.isCompleted }
        
        if !hasToday {
            // Start checking from yesterday
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        while true {
            let hasReflection = reflections.contains { 
                calendar.isDate($0.date, inSameDayAs: checkDate) && $0.isCompleted 
            }
            
            if hasReflection {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        currentStreak = streak
    }
    
    private func saveReflection() {
        if let existing = todayReflection {
            existing.wentWell = wentWell
            existing.couldImprove = couldImprove
            existing.nextAction = nextAction
            existing.gratitude = gratitude
            existing.learnings = learnings
            existing.energyLevel = energyLevel
            existing.moodScore = moodScore
            existing.isCompleted = !wentWell.isEmpty || !couldImprove.isEmpty
        } else {
            let newReflection = Reflection(
                wentWell: wentWell,
                couldImprove: couldImprove,
                nextAction: nextAction,
                gratitude: gratitude,
                energyLevel: energyLevel,
                moodScore: moodScore,
                learnings: learnings,
                isCompleted: !wentWell.isEmpty || !couldImprove.isEmpty
            )
            modelContext.insert(newReflection)
        }
        
        withAnimation(.spring(response: 0.4)) {
            showingSavedAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingSavedAnimation = false
            }
            calculateStreak()
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: Reflection.self, inMemory: true)
        .frame(width: 900, height: 800)
}
