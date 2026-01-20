import SwiftUI
import SwiftData

@main
struct ReflectApp: App {
    @State private var showMigrationError = false
    @State private var migrationErrorMessage = ""

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BottleneckEntry.self,
            ToolDevelopment.self,
            QuestionLog.self,
            Goal.self,
            DailyRetrospective.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 마이그레이션 실패 로그
            print("⚠️ ModelContainer 생성 실패: \(error)")
            print("💡 설정 > 모든 데이터 삭제로 해결하거나, 앱을 재설치하세요.")

            // 임시로 메모리에서 실행 (데이터 저장 안됨)
            let tempConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [tempConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // 키보드 단축키 추가
            CommandGroup(after: .newItem) {
                Button("새 병목 지점 기록") {
                    NotificationCenter.default.post(name: .addNewEntry, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])

                Divider()

                Button("대시보드로 이동") {
                    NotificationCenter.default.post(name: .showDashboard, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }

        // 회고 플로우 창
        WindowGroup("목표 회고", for: String.self) { $goalId in
            if let goalId = goalId {
                ReflectionWindowView(goalId: goalId)
                    .modelContainer(sharedModelContainer)
            }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 700)
    }
}

// MARK: - Reflection Window View
struct ReflectionWindowView: View {
    let goalId: String
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]

    var goal: Goal? {
        goals.first { $0.id.uuidString == goalId }
    }

    var body: some View {
        if let goal = goal {
            ReflectionFlowView(goal: goal)
        } else {
            ContentUnavailableView("목표를 찾을 수 없습니다", systemImage: "exclamationmark.triangle")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let addNewEntry = Notification.Name("addNewEntry")
    static let showDashboard = Notification.Name("showDashboard")
}
