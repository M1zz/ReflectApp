import SwiftUI

struct TimelineListView: View {
    @Environment(ReflectionStore.self) var store
    @State private var filterTag: String? = nil
    @State private var searchText = ""
    
    var filteredEntries: [ReflectionEntry] {
        var result = store.entries
        if let tag = filterTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        if !searchText.isEmpty {
            result = result.filter { entry in
                entry.answers.contains { $0.answer.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return result
    }
    
    var allTags: [String] {
        var tags: [String: Int] = [:]
        store.entries.forEach { e in e.tags.forEach { tags[$0, default: 0] += 1 } }
        return tags.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("타임라인")
                            .font(.system(size: 26, weight: .bold))
                        Text("모든 회고 기록을 한눈에")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(filteredEntries.count)개의 회고")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.tertiary)
                    TextField("회고 내용 검색...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                
                // Tag filters
                if !allTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            filterButton(nil, label: "전체")
                            ForEach(allTags, id: \.self) { tag in
                                filterButton(tag, label: tag)
                            }
                        }
                    }
                }
                
                if filteredEntries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundStyle(.tertiary)
                        Text("회고가 없습니다")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredEntries) { entry in
                            TimelineEntryCard(entry: entry) {
                                withAnimation { store.deleteEntry(entry) }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    func filterButton(_ tag: String?, label: String) -> some View {
        let isActive = filterTag == tag
        return Button {
            withAnimation { filterTag = tag }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isActive ? Color.orange.opacity(0.15) : Color.primary.opacity(0.05))
                )
                .foregroundStyle(isActive ? .orange : .secondary)
        }
        .buttonStyle(.plain)
    }
}

struct TimelineEntryCard: View {
    let entry: ReflectionEntry
    var onDelete: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Date column
            VStack(spacing: 2) {
                Text(dayString)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                Text(timeString)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 60, alignment: .trailing)
            
            // Content
            VStack(alignment: .leading, spacing: 10) {
                if !entry.emotion.isEmpty {
                    Text(entry.emotion)
                        .font(.system(size: 20))
                }
                
                ForEach(entry.answers) { qa in
                    if !qa.answer.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(qa.question.components(separatedBy: "\n").first ?? "")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.tertiary)
                            Text(qa.answer)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                    }
                }
                
                // Tags
                if !entry.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.primary.opacity(0.05)))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                // Energy
                if entry.energyLevel > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...10, id: \.self) { level in
                            Circle()
                                .fill(level <= entry.energyLevel
                                      ? (entry.energyLevel <= 3 ? Color.red : entry.energyLevel <= 6 ? .orange : .green)
                                      : Color.primary.opacity(0.06))
                                .frame(width: 6, height: 6)
                        }
                        Text("\(entry.energyLevel)/10")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Delete
            if isHovering {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
        .onHover { isHovering = $0 }
    }
    
    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: entry.date)
    }
    
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: entry.date)
    }
}
