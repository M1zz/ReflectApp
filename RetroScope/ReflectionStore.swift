import Foundation
import SwiftUI

@Observable
class ReflectionStore {
    var entries: [ReflectionEntry] = []
    var patterns: [DiscoveredPattern] = []
    
    private let entriesKey = "retroscope_entries"
    private let patternsKey = "retroscope_patterns"
    
    init() {
        loadEntries()
        loadPatterns()
    }
    
    // MARK: - Persistence
    func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: entriesKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([ReflectionEntry].self, from: data) {
            entries = decoded
        }
    }
    
    func saveEntries() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
    
    func loadPatterns() {
        guard let data = UserDefaults.standard.data(forKey: patternsKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([DiscoveredPattern].self, from: data) {
            patterns = decoded
        }
    }
    
    func savePatterns() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(patterns) {
            UserDefaults.standard.set(data, forKey: patternsKey)
        }
    }
    
    // MARK: - Actions
    func addEntry(_ entry: ReflectionEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
        patterns = PatternEngine.analyze(entries: entries, existingPatterns: patterns)
        savePatterns()
    }
    
    func deleteEntry(_ entry: ReflectionEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
        patterns = PatternEngine.analyze(entries: entries, existingPatterns: patterns)
        savePatterns()
    }
    
    func resolvePattern(_ pattern: DiscoveredPattern) {
        if let idx = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[idx].isResolved = true
            patterns[idx].resolvedAt = Date()
            savePatterns()
        }
    }
    
    func dismissPattern(_ pattern: DiscoveredPattern) {
        patterns.removeAll { $0.id == pattern.id }
        savePatterns()
    }
    
    // MARK: - Computed
    var activePatterns: [DiscoveredPattern] {
        patterns.filter { !$0.isResolved }
    }
    
    var resolvedPatterns: [DiscoveredPattern] {
        patterns.filter { $0.isResolved }
    }
    
    var averageEnergy: Double {
        let withEnergy = entries.filter { $0.energyLevel > 0 }
        guard !withEnergy.isEmpty else { return 0 }
        return Double(withEnergy.reduce(0) { $0 + $1.energyLevel }) / Double(withEnergy.count)
    }
    
    var tagDistribution: [(String, Int)] {
        var counts: [String: Int] = [:]
        entries.forEach { e in e.tags.forEach { counts[$0, default: 0] += 1 } }
        return counts.sorted { $0.value > $1.value }
    }
    
    var emotionDistribution: [(String, Int)] {
        var counts: [String: Int] = [:]
        entries.forEach { if !$0.emotion.isEmpty { counts[$0.emotion, default: 0] += 1 } }
        return counts.sorted { $0.value > $1.value }
    }
    
    var streakDays: Int {
        guard !entries.isEmpty else { return 0 }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastDate = cal.startOfDay(for: entries[0].date)
        let diffDays = cal.dateComponents([.day], from: lastDate, to: today).day ?? 0
        if diffDays > 1 { return 0 }
        
        let uniqueDates = Set(entries.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        var streak = 1
        for i in 1..<uniqueDates.count {
            let diff = cal.dateComponents([.day], from: uniqueDates[i], to: uniqueDates[i-1]).day ?? 0
            if diff == 1 { streak += 1 }
            else { break }
        }
        return streak
    }
    
    // MARK: - Export / Import
    func exportJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        struct ExportData: Codable {
            let entries: [ReflectionEntry]
            let patterns: [DiscoveredPattern]
            let exportedAt: Date
        }

        let data = ExportData(entries: entries, patterns: patterns, exportedAt: Date())
        return try? encoder.encode(data)
    }
    
    func importJSON(from data: Data) -> Int {
        struct ExportData: Codable {
            let entries: [ReflectionEntry]
            let patterns: [DiscoveredPattern]?
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let imported = try? decoder.decode(ExportData.self, from: data) else { return 0 }

        let existingIds = Set(entries.map { $0.id })
        let newEntries = imported.entries.filter { !existingIds.contains($0.id) }
        entries = newEntries + entries
        entries.sort { $0.date > $1.date }
        saveEntries()

        patterns = PatternEngine.analyze(entries: entries, existingPatterns: patterns)
        savePatterns()

        return newEntries.count
    }

    // MARK: - Dummy Data for Testing
    func clearAllData() {
        entries = []
        patterns = []
        saveEntries()
        savePatterns()
    }

    func loadDummyData() {
        // Simple JSON import approach
        let jsonString = """
        {
            "entries": [
                {
                    "id": "00000000-0000-0000-0000-000000000001",
                    "date": "\(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -2, to: Date())!))",
                    "answers": [
                        {"id": "11111111-1111-1111-1111-111111111111", "questionId": "proud_moment", "question": "오늘 하루 중 너무나 뿌듯한 순간이 있었나요?", "answer": "팀 회의에서 내 아이디어가 채택되었다. 오랜 시간 고민했던 것이라 뿌듯했다."},
                        {"id": "11111111-1111-1111-1111-111111111112", "questionId": "never_again", "question": "다시 반복하고 싶지 않은 일이 있었나요?", "answer": "회의가 너무 길어져서 다른 업무 시간이 부족했다. 회의 시간 관리가 필요하다."},
                        {"id": "11111111-1111-1111-1111-111111111113", "questionId": "energy_drain", "question": "에너지가 확 빠지는 순간이 있었나요?", "answer": "오후에 불필요한 미팅이 3개나 있어서 집중이 안 되었다."}
                    ],
                    "tags": ["업무", "의사결정", "시간관리"],
                    "emotion": "😤",
                    "energyLevel": 4
                },
                {
                    "id": "00000000-0000-0000-0000-000000000002",
                    "date": "\(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -4, to: Date())!))",
                    "answers": [
                        {"id": "22222222-2222-2222-2222-222222222221", "questionId": "self_praise", "question": "스스로 자랑스러운 순간이 있었나요?", "answer": "미루고 있던 문서 작업을 드디어 마무리했다."},
                        {"id": "22222222-2222-2222-2222-222222222222", "questionId": "never_again", "question": "다시 반복하고 싶지 않은 일이 있었나요?", "answer": "또 회의 시간이 길어져서 업무가 밀렸다. 회의 효율화가 시급하다."},
                        {"id": "22222222-2222-2222-2222-222222222223", "questionId": "energy_drain", "question": "에너지가 확 빠지는 순간이 있었나요?", "answer": "끝없이 이어지는 이메일과 슬랙 메시지. 집중할 시간이 없었다."}
                    ],
                    "tags": ["업무", "시간관리"],
                    "emotion": "😔",
                    "energyLevel": 3
                },
                {
                    "id": "00000000-0000-0000-0000-000000000003",
                    "date": "\(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -6, to: Date())!))",
                    "answers": [
                        {"id": "33333333-3333-3333-3333-333333333331", "questionId": "energy_charge", "question": "에너지가 확 차오른 순간은요?", "answer": "동료와 프로젝트에 대해 깊이 있는 대화를 나눴다."},
                        {"id": "33333333-3333-3333-3333-333333333332", "questionId": "relationship_moment", "question": "누군가와의 관계에서 인상 깊었던 순간이 있나요?", "answer": "팀원이 내 업무를 도와줘서 감사했다. 관계가 좋아지고 있다."},
                        {"id": "33333333-3333-3333-3333-333333333333", "questionId": "never_again", "question": "다시 반복하고 싶지 않은 일이 있었나요?", "answer": "회의 준비 없이 참석해서 시간만 낭비했다."}
                    ],
                    "tags": ["관계", "업무", "시간관리"],
                    "emotion": "😊",
                    "energyLevel": 7
                },
                {
                    "id": "00000000-0000-0000-0000-000000000004",
                    "date": "\(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -8, to: Date())!))",
                    "answers": [
                        {"id": "44444444-4444-4444-4444-444444444441", "questionId": "kept_postponing", "question": "계속 미루고 있는 것이 있나요?", "answer": "운동을 시작하려고 했는데 또 미뤘다. 시간관리가 안 된다."},
                        {"id": "44444444-4444-4444-4444-444444444442", "questionId": "energy_drain", "question": "에너지가 확 빠지는 순간이 있었나요?", "answer": "긴 회의 후 남은 에너지가 없었다. 회의가 너무 많다."},
                        {"id": "44444444-4444-4444-4444-444444444443", "questionId": "body_signal", "question": "몸이 보낸 신호가 있었나요?", "answer": "어깨가 뻣뻣하고 눈이 피로하다. 휴식이 필요하다."}
                    ],
                    "tags": ["건강", "시간관리", "업무"],
                    "emotion": "😰",
                    "energyLevel": 3
                },
                {
                    "id": "00000000-0000-0000-0000-000000000005",
                    "date": "\(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -10, to: Date())!))",
                    "answers": [
                        {"id": "55555555-5555-5555-5555-555555555551", "questionId": "decision_made", "question": "오늘 내린 결정 중 가장 중요했던 것은 무엇인가요?", "answer": "회의 시간을 줄이기로 결정했다. 팀에 제안할 예정이다."},
                        {"id": "55555555-5555-5555-5555-555555555552", "questionId": "never_again", "question": "다시 반복하고 싶지 않은 일이 있었나요?", "answer": "회의가 또 계획 없이 진행되어 시간만 낭비했다."},
                        {"id": "55555555-5555-5555-5555-555555555553", "questionId": "gratitude", "question": "오늘 감사한 것이 있다면 무엇인가요?", "answer": "팀이 내 의견을 경청해줘서 감사하다."}
                    ],
                    "tags": ["업무", "의사결정", "관계"],
                    "emotion": "😤",
                    "energyLevel": 4
                },
                {
                    "id": "00000000-0000-0000-0000-000000000006",
                    "date": "\(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -11, to: Date())!))",
                    "answers": [
                        {"id": "66666666-6666-6666-6666-666666666661", "questionId": "proud_moment", "question": "오늘 하루 중 너무나 뿌듯한 순간이 있었나요?", "answer": "어려운 버그를 해결했다. 시간이 오래 걸렸지만 해냈다."},
                        {"id": "66666666-6666-6666-6666-666666666662", "questionId": "energy_charge", "question": "에너지가 확 차오른 순간은요?", "answer": "코딩에 몰입하는 시간이 좋았다. 관계 속 대화보다 혼자 집중할 때 에너지가 생긴다."},
                        {"id": "66666666-6666-6666-6666-666666666663", "questionId": "surprised_self", "question": "오늘 나 자신에 대해 새롭게 알게 된 것이 있나요?", "answer": "나는 혼자 일할 때 더 효율적이라는 것을 깨달았다."}
                    ],
                    "tags": ["업무", "학습", "관계"],
                    "emotion": "🔥",
                    "energyLevel": 8
                },
                {
                    "id": "00000000-0000-0000-0000-000000000007",
                    "date": "\(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -13, to: Date())!))",
                    "answers": [
                        {"id": "77777777-7777-7777-7777-777777777771", "questionId": "if_redo", "question": "오늘을 다시 살 수 있다면 딱 하나 바꾸고 싶은 것은?", "answer": "회의를 거절했을 것이다. 시간관리를 더 잘하고 싶다."},
                        {"id": "77777777-7777-7777-7777-777777777772", "questionId": "energy_drain", "question": "에너지가 확 빠지는 순간이 있었나요?", "answer": "또 긴 회의. 관계는 좋지만 시간이 아깝다."},
                        {"id": "77777777-7777-7777-7777-777777777773", "questionId": "body_signal", "question": "몸이 보낸 신호가 있었나요?", "answer": "머리가 아프고 피곤하다."}
                    ],
                    "tags": ["업무", "시간관리", "건강"],
                    "emotion": "😮‍💨",
                    "energyLevel": 2
                },
                {
                    "id": "00000000-0000-0000-0000-000000000008",
                    "date": "\(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -14, to: Date())!))",
                    "answers": [
                        {"id": "88888888-8888-8888-8888-888888888881", "questionId": "gratitude", "question": "오늘 감사한 것이 있다면 무엇인가요?", "answer": "팀원들과의 관계가 좋아서 감사하다."},
                        {"id": "88888888-8888-8888-8888-888888888882", "questionId": "relationship_moment", "question": "누군가와의 관계에서 인상 깊었던 순간이 있나요?", "answer": "동료와 깊은 대화를 나눴다. 관계가 더 돈독해졌다."},
                        {"id": "88888888-8888-8888-8888-888888888883", "questionId": "never_again", "question": "다시 반복하고 싶지 않은 일이 있었나요?", "answer": "회의에서 준비 부족으로 제대로 발언하지 못했다."}
                    ],
                    "tags": ["관계", "업무"],
                    "emotion": "😌",
                    "energyLevel": 6
                }
            ]
        }
        """

        guard let jsonData = jsonString.data(using: .utf8) else { return }
        let _ = importJSON(from: jsonData)
    }
}
