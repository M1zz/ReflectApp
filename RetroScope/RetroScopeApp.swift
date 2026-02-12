import SwiftUI

@main
struct RetroScopeApp: App {
    @State private var store = ReflectionStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 960, height: 720)
    }
}
