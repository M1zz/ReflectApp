import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reflections: [Reflection]
    
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = true
    @AppStorage("reminderTime") private var reminderTime: Double = 21.0 // 9 PM
    @AppStorage("showStreak") private var showStreak: Bool = true
    @AppStorage("defaultEnergyLevel") private var defaultEnergyLevel: Int = 3
    @AppStorage("defaultMoodScore") private var defaultMoodScore: Int = 3
    
    @State private var showingResetAlert: Bool = false
    @State private var showingExportAlert: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Settings sections
                VStack(spacing: 24) {
                    notificationSettings
                    displaySettings
                    defaultsSettings
                    dataSettings
                    aboutSection
                }
                .frame(maxWidth: 600)
            }
            .padding(40)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("설정")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("앱을 나에게 맞게 커스터마이즈하세요")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
    }
    
    // MARK: - Notification Settings
    private var notificationSettings: some View {
        settingsSection(title: "알림", icon: "bell.fill", color: Color(hex: "f472b6")) {
            VStack(spacing: 16) {
                Toggle(isOn: $reminderEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("매일 회고 알림")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Text("설정한 시간에 회고 알림을 보내드려요")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "818cf8")))
                
                if reminderEnabled {
                    HStack {
                        Text("알림 시간")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(formatTime(reminderTime))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "818cf8"))
                    }
                    
                    Slider(value: $reminderTime, in: 6...23, step: 0.5)
                        .tint(Color(hex: "818cf8"))
                }
            }
        }
    }
    
    // MARK: - Display Settings
    private var displaySettings: some View {
        settingsSection(title: "화면", icon: "paintbrush.fill", color: Color(hex: "818cf8")) {
            Toggle(isOn: $showStreak) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("연속 기록 표시")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text("오늘 화면에서 연속 회고 일수를 보여줘요")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "818cf8")))
        }
    }
    
    // MARK: - Defaults Settings
    private var defaultsSettings: some View {
        settingsSection(title: "기본값", icon: "slider.horizontal.3", color: Color(hex: "fbbf24")) {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("기본 에너지 레벨")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                defaultEnergyLevel = level
                            } label: {
                                Circle()
                                    .fill(level <= defaultEnergyLevel ? 
                                          Color(hex: "fbbf24") : 
                                          Color.white.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("\(level)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(level <= defaultEnergyLevel ? 
                                                            Color(hex: "1a1a2e") : 
                                                            Color.white.opacity(0.4))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("기본 기분 점수")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                defaultMoodScore = level
                            } label: {
                                Circle()
                                    .fill(level <= defaultMoodScore ? 
                                          Color(hex: "818cf8") : 
                                          Color.white.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("\(level)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(level <= defaultMoodScore ? 
                                                            Color(hex: "1a1a2e") : 
                                                            Color.white.opacity(0.4))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Data Settings
    private var dataSettings: some View {
        settingsSection(title: "데이터", icon: "externaldrive.fill", color: Color(hex: "4ade80")) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("총 회고 기록")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Text("저장된 모든 회고 데이터")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Text("\(reflections.count)개")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "4ade80"))
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                Button {
                    showingExportAlert = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("데이터 내보내기")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
                .alert("데이터 내보내기", isPresented: $showingExportAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text("곧 지원될 예정이에요!")
                }
                
                Button {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("모든 데이터 삭제")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "ef4444"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "ef4444").opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .alert("정말 삭제하시겠어요?", isPresented: $showingResetAlert) {
                    Button("취소", role: .cancel) { }
                    Button("삭제", role: .destructive) {
                        deleteAllData()
                    }
                } message: {
                    Text("모든 회고 기록이 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없어요.")
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        settingsSection(title: "앱 정보", icon: "info.circle.fill", color: Color(hex: "38bdf8")) {
            VStack(spacing: 16) {
                HStack {
                    Text("버전")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("제작")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("Reflect")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                Text("매일 더 나은 나를 위한 회고 앱")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
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
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            content()
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
    
    private func formatTime(_ time: Double) -> String {
        let hour = Int(time)
        let minute = Int((time - Double(hour)) * 60)
        let period = hour >= 12 ? "오후" : "오전"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return minute == 0 ? "\(period) \(displayHour)시" : "\(period) \(displayHour)시 \(minute)분"
    }
    
    private func deleteAllData() {
        for reflection in reflections {
            modelContext.delete(reflection)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Reflection.self, inMemory: true)
        .frame(width: 700, height: 800)
}
