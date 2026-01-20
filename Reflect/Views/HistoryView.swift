import SwiftUI
import SwiftData

// MARK: - History List View (전체 기록 목록)
struct HistoryListView: View {
    @Binding var selectedEntry: BottleneckEntry?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BottleneckEntry.createdAt, order: .reverse) private var entries: [BottleneckEntry]
    @Query(sort: \DailyRetrospective.date, order: .reverse) private var retrospectives: [DailyRetrospective]

    @State private var selectedTab: HistoryTab = .bottleneck
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var sortOption: SortOption = .date
    @State private var filterScore: Int?

    enum HistoryTab: String, CaseIterable {
        case bottleneck = "병목 기록"
        case retrospective = "5분 회고"
    }

    enum SortOption: String, CaseIterable {
        case date = "날짜순"
        case roi = "ROI순"
        case wasted = "낭비시간순"
        case frequency = "빈도순"
    }

    private var filteredEntries: [BottleneckEntry] {
        var result = entries

        // 검색어 필터
        if !searchText.isEmpty {
            result = result.filter {
                $0.taskName.localizedCaseInsensitiveContains(searchText) ||
                $0.delayReason.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // 태그 필터
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }

        // 점수 필터
        if let score = filterScore {
            result = result.filter { $0.automationScore >= score }
        }

        // 정렬
        switch sortOption {
        case .date:
            break // 이미 날짜순 정렬됨
        case .roi:
            result.sort { $0.roiScore > $1.roiScore }
        case .wasted:
            result.sort { $0.weeklyWastedMinutes > $1.weeklyWastedMinutes }
        case .frequency:
            result.sort { $0.weeklyFrequency > $1.weeklyFrequency }
        }

        return result
    }

    private var allTags: [String] {
        Array(Set(entries.flatMap { $0.tags })).sorted()
    }

    private var totalWastedMinutes: Int {
        filteredEntries.reduce(0) { $0 + $1.weeklyWastedMinutes }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 탭 선택
            Picker("", selection: $selectedTab) {
                ForEach(HistoryTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // 탭별 콘텐츠
            switch selectedTab {
            case .bottleneck:
                bottleneckHistoryView
            case .retrospective:
                retrospectiveHistoryView
            }
        }
    }

    // MARK: - Bottleneck History View
    private var bottleneckHistoryView: some View {
        VStack(spacing: 0) {
            // 상단 헤더 및 필터
            headerSection

            // 검색 및 필터
            filterSection

            // 목록
            if filteredEntries.isEmpty {
                emptyState
            } else {
                entryList
            }
        }
    }

    // MARK: - Retrospective History View
    private var retrospectiveHistoryView: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("5분 회고 기록")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("\(retrospectives.count)개의 회고")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            // 회고 목록
            if retrospectives.isEmpty {
                ContentUnavailableView(
                    "아직 회고가 없습니다",
                    systemImage: "sparkles",
                    description: Text("오늘 탭에서 5분 회고를 작성해보세요")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(retrospectives) { retro in
                            RetrospectiveHistoryCard(retrospective: retro)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("전체 기록")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("\(filteredEntries.count)개 항목 • 주간 낭비 \(BottleneckEntry.formatMinutes(totalWastedMinutes))")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 정렬 옵션
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        sortOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sortOption.rawValue)
                }
                .font(.body)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.controlBackgroundColor))
                .clipShape(Capsule())
            }
            .menuStyle(.borderlessButton)
        }
        .padding()
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 12) {
            // 검색
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("검색...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 태그 필터
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 전체 버튼
                    FilterChip(
                        label: "전체",
                        isSelected: selectedTag == nil,
                        action: { selectedTag = nil }
                    )

                    // 점수 필터
                    Menu {
                        Button("전체") { filterScore = nil }
                        ForEach(1...5, id: \.self) { score in
                            Button("\(score)점 이상") { filterScore = score }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.body)
                            Text(filterScore.map { "\($0)+ 점" } ?? "점수")
                        }
                        .font(.body)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(filterScore != nil ? Color.yellow.opacity(0.2) : Color(.controlBackgroundColor))
                        .foregroundStyle(filterScore != nil ? .yellow : .secondary)
                        .clipShape(Capsule())
                    }
                    .menuStyle(.borderlessButton)

                    Divider()
                        .frame(height: 20)

                    // 태그들
                    ForEach(allTags, id: \.self) { tag in
                        FilterChip(
                            label: "#\(tag)",
                            isSelected: selectedTag == tag,
                            action: { selectedTag = selectedTag == tag ? nil : tag }
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    // MARK: - Entry List
    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredEntries) { entry in
                    HistoryEntryRow(entry: entry, isSelected: selectedEntry?.id == entry.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedEntry = entry
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(entry)
                                if selectedEntry?.id == entry.id {
                                    selectedEntry = nil
                                }
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("검색 결과가 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            if !searchText.isEmpty || selectedTag != nil || filterScore != nil {
                Button("필터 초기화") {
                    searchText = ""
                    selectedTag = nil
                    filterScore = nil
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue.opacity(0.3) : Color(.controlBackgroundColor))
                .foregroundStyle(isSelected ? .blue : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - History Entry Row
struct HistoryEntryRow: View {
    let entry: BottleneckEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 날짜
            VStack(spacing: 2) {
                Text(entry.shortDate)
                    .font(.body.bold())
                Text(dayOfWeek)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)

            // 도구화 점수
            Text(entry.automationEmoji)
                .font(.title3)

            // 메인 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.taskName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // 시간 정보
                    Text("\(entry.estimatedMinutes)분→\(entry.actualMinutes)분")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if entry.wastedMinutes > 0 {
                        Text("+\(entry.wastedMinutes)분")
                            .font(.body.bold())
                            .foregroundStyle(.red)
                    }

                    Text("주 \(entry.weeklyFrequency)회")
                        .font(.body)
                        .foregroundStyle(.blue)
                }

                // 태그
                if !entry.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.body)
                                .foregroundStyle(.purple)
                        }
                        if entry.tags.count > 2 {
                            Text("+\(entry.tags.count - 2)")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // ROI
            VStack(alignment: .trailing, spacing: 2) {
                Text("ROI")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f", entry.roiScore))
                    .font(.body.bold().monospacedDigit())
                    .foregroundStyle(.purple)
            }
        }
        .padding(12)
        .background(isSelected ? Color.blue.opacity(0.15) : Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: entry.createdAt)
    }
}

// MARK: - Retrospective History Card
struct RetrospectiveHistoryCard: View {
    let retrospective: DailyRetrospective
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더 (날짜 + 토글)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(retrospective.formattedDate)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    // 완성도 표시
                    HStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index < retrospective.completionCount ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // 미리보기 (접힌 상태)
            if !isExpanded {
                HStack(spacing: 16) {
                    if !retrospective.good.isEmpty {
                        Label(retrospective.good, systemImage: "face.smiling")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            // 상세 내용 (펼친 상태)
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if !retrospective.good.isEmpty {
                        RetrospectiveDetailRow(emoji: "😊", title: "Good", content: retrospective.good)
                    }
                    if !retrospective.bad.isEmpty {
                        RetrospectiveDetailRow(emoji: "😞", title: "Bad", content: retrospective.bad)
                    }
                    if !retrospective.ideas.isEmpty {
                        RetrospectiveDetailRow(emoji: "💡", title: "Ideas", content: retrospective.ideas)
                    }
                    if !retrospective.actions.isEmpty {
                        RetrospectiveDetailRow(emoji: "⚡", title: "Actions", content: retrospective.actions)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RetrospectiveDetailRow: View {
    let emoji: String
    let title: String
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji)
                .font(.body)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.bold())
                    .foregroundStyle(.secondary)
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    HistoryListView(selectedEntry: .constant(nil))
        .modelContainer(for: [BottleneckEntry.self, DailyRetrospective.self], inMemory: true)
        .frame(width: 500, height: 700)
}
