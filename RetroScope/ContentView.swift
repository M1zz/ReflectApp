import SwiftUI

enum AppTab: String, CaseIterable {
    case write = "회고 작성"
    case patterns = "발견된 패턴"
    case timeline = "타임라인"
    case insights = "인사이트"
    
    var icon: String {
        switch self {
        case .write: return "square.and.pencil"
        case .patterns: return "eye.trianglebadge.exclamationmark"
        case .timeline: return "calendar.badge.clock"
        case .insights: return "chart.bar.xaxis"
        }
    }
}

struct ContentView: View {
    @Environment(ReflectionStore.self) var store
    @State private var selectedTab: AppTab = .write
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            ZStack {
                detailView
                
                if showToast {
                    VStack {
                        Spacer()
                        toastView
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Sidebar
    var sidebar: some View {
        VStack(spacing: 0) {
            // Logo
            VStack(spacing: 4) {
                Text("Retro·Scope")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                Text("패턴 인지 회고")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(2)
            }
            .padding(.vertical, 20)
            
            Divider().padding(.horizontal)
            
            // Tabs
            VStack(spacing: 2) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    sidebarButton(tab)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Stats summary
            if !store.entries.isEmpty {
                VStack(spacing: 8) {
                    Divider().padding(.horizontal)
                    HStack {
                        Label("\(store.entries.count)", systemImage: "doc.text")
                        Spacer()
                        if store.activePatterns.count > 0 {
                            Label("\(store.activePatterns.count)", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
    }
    
    func sidebarButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                Spacer()
                if tab == .patterns && store.activePatterns.count > 0 {
                    Text("\(store.activePatterns.count)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.orange))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == tab ? Color.accentColor.opacity(0.12) : .clear)
            )
            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Detail
    @ViewBuilder
    var detailView: some View {
        switch selectedTab {
        case .write:
            WriteView(onSave: { message in
                triggerToast(message)
            })
        case .patterns:
            PatternListView()
        case .timeline:
            TimelineListView()
        case .insights:
            InsightDashboardView()
        }
    }
    
    // MARK: - Toast
    var toastView: some View {
        Text(toastMessage)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }
    
    func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.3)) { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }
}
