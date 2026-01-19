import SwiftUI
import SwiftData

enum NavigationItem: String, CaseIterable, Identifiable {
    case today = "오늘"
    case history = "기록"
    case insights = "인사이트"
    case settings = "설정"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .history: return "calendar"
        case .insights: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: NavigationItem = .today
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "1a1a2e"),
                        Color(hex: "16213e")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                switch selectedItem {
                case .today:
                    TodayView()
                case .history:
                    HistoryView()
                case .insights:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            insertSampleDataIfNeeded()
        }
    }
    
    private func insertSampleDataIfNeeded() {
        if reflections.isEmpty {
            for sample in Reflection.sampleData {
                modelContext.insert(sample)
            }
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @Binding var selectedItem: NavigationItem
    
    var body: some View {
        List(selection: $selectedItem) {
            Section {
                ForEach(NavigationItem.allCases) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Reflect")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .padding(.bottom, 8)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
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
        .modelContainer(for: Reflection.self, inMemory: true)
}
