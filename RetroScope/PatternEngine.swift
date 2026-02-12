import Foundation

struct PatternEngine {
    
    static func analyze(entries: [ReflectionEntry], existingPatterns: [DiscoveredPattern]) -> [DiscoveredPattern] {
        guard entries.count >= 2 else { return [] }

        var patterns: [DiscoveredPattern] = []
        let resolvedIds = Set(existingPatterns.filter { $0.isResolved }.map { $0.id })

        // 1. Recurring tag combinations
        patterns.append(contentsOf: analyzeTagPatterns(entries))

        // 2. Emotion patterns
        patterns.append(contentsOf: analyzeEmotionPatterns(entries))

        // 3. Energy patterns
        if let p = analyzeEnergyPattern(entries) { patterns.append(p) }

        // 4. Keyword patterns from text
        patterns.append(contentsOf: analyzeKeywordPatterns(entries))

        // 5. Question-specific patterns (which questions always get answered similarly)
        patterns.append(contentsOf: analyzeQuestionPatterns(entries))

        // 6. Time-based patterns
        patterns.append(contentsOf: analyzeTimePatterns(entries))

        // 7. Positive patterns (strengths)
        if let p = analyzePositivePattern(entries) { patterns.append(p) }

        // 8. ⭐️ Causal relationship analysis
        patterns = analyzeCausalRelationships(patterns: patterns)

        // Preserve resolved state
        for i in patterns.indices {
            if resolvedIds.contains(patterns[i].id) {
                patterns[i].isResolved = true
                patterns[i].resolvedAt = existingPatterns.first(where: { $0.id == patterns[i].id })?.resolvedAt
            }
        }

        // Sort: unresolved first, then by severity
        let severityOrder: [PatternSeverity: Int] = [.high: 0, .mid: 1, .low: 2, .positive: 3]
        patterns.sort { a, b in
            if a.isResolved != b.isResolved { return !a.isResolved }
            return (severityOrder[a.severity] ?? 9) < (severityOrder[b.severity] ?? 9)
        }

        return patterns
    }
    
    // MARK: - Tag Patterns
    static func analyzeTagPatterns(_ entries: [ReflectionEntry]) -> [DiscoveredPattern] {
        var tagGroups: [String: [ReflectionEntry]] = [:]
        
        for entry in entries {
            for tag in entry.tags {
                tagGroups[tag, default: []].append(entry)
            }
            // Tag combos
            let sorted = entry.tags.sorted()
            for i in 0..<sorted.count {
                for j in (i+1)..<sorted.count {
                    let key = "\(sorted[i])+\(sorted[j])"
                    tagGroups[key, default: []].append(entry)
                }
            }
        }
        
        return tagGroups.compactMap { combo, items -> DiscoveredPattern? in
            guard items.count >= 3 else { return nil }
            let isCombo = combo.contains("+")
            let tags = combo.split(separator: "+").map(String.init)
            
            return DiscoveredPattern(
                id: "tag_\(combo)",
                type: .recurringTheme,
                name: isCombo ? "\"\(tags[0])\"와 \"\(tags[1])\"이 함께 등장" : "\"\(combo)\" 반복 언급",
                description: "최근 \(items.count)회의 회고에서 \(isCombo ? "이 두 영역이 함께" : "이 주제가 반복적으로") 등장합니다.",
                frequency: items.count,
                severity: items.count >= 5 ? .high : items.count >= 4 ? .mid : .low,
                evidence: items.prefix(4).map { PatternEvidence(date: $0.date, excerpt: $0.answers.first(where: { !$0.answer.isEmpty })?.answer.prefix(80).appending("...") ?? "") },
                insight: isCombo
                    ? "이 두 영역이 함께 등장한다는 것은 서로 영향을 주고받고 있을 가능성이 높습니다. 하나를 해결하면 다른 하나도 나아질 수 있습니다."
                    : "같은 주제가 반복될 때는 의지력이 아닌 환경/프로세스를 바꿔야 할 때입니다.",
                createdAt: Date(),
                isResolved: false
            )
        }
    }
    
    // MARK: - Emotion Patterns
    static func analyzeEmotionPatterns(_ entries: [ReflectionEntry]) -> [DiscoveredPattern] {
        let recent = Array(entries.prefix(10))
        var emotionGroups: [String: [ReflectionEntry]] = [:]
        
        for entry in recent where !entry.emotion.isEmpty {
            emotionGroups[entry.emotion, default: []].append(entry)
        }
        
        let negativeEmojis: Set<String> = ["😤", "😔", "😰", "😮‍💨"]
        let emojiNames: [String: String] = ["😤": "답답함", "😔": "우울", "😰": "불안", "😮‍💨": "지침"]
        
        return emotionGroups.compactMap { emoji, items -> DiscoveredPattern? in
            guard items.count >= 3, negativeEmojis.contains(emoji) else { return nil }
            let name = emojiNames[emoji] ?? emoji
            
            return DiscoveredPattern(
                id: "emotion_\(emoji)",
                type: .emotionPattern,
                name: "\(name) 감정이 지속적으로 등장",
                description: "최근 10회 회고 중 \(items.count)회에서 \"\(name)\" 감정이 나타납니다.",
                frequency: items.count,
                severity: items.count >= 5 ? .high : .mid,
                evidence: items.prefix(4).map { PatternEvidence(date: $0.date, excerpt: $0.answers.first(where: { !$0.answer.isEmpty })?.answer.prefix(80).appending("...") ?? "") },
                insight: "감정은 신호입니다. \"\(name)\"이 반복적으로 나타난다면, 이 감정을 유발하는 트리거를 찾아보세요. 특정 사람, 상황, 시간대와 연결될 수 있습니다.",
                createdAt: Date(),
                isResolved: false
            )
        }
    }
    
    // MARK: - Energy Pattern
    static func analyzeEnergyPattern(_ entries: [ReflectionEntry]) -> DiscoveredPattern? {
        let recent = entries.prefix(7).filter { $0.energyLevel > 0 }
        guard recent.count >= 3 else { return nil }
        
        let avg = Double(recent.reduce(0) { $0 + $1.energyLevel }) / Double(recent.count)
        guard avg <= 4 else { return nil }
        
        return DiscoveredPattern(
            id: "energy_low",
            type: .energyPattern,
            name: "에너지 레벨 지속 저하",
            description: "최근 \(recent.count)회 회고의 평균 에너지가 \(String(format: "%.1f", avg))/10입니다.",
            frequency: recent.count,
            severity: avg <= 3 ? .high : .mid,
            evidence: recent.prefix(4).map { PatternEvidence(date: $0.date, excerpt: "에너지 \($0.energyLevel)/10") },
            insight: "낮은 에너지가 반복될 때 흔한 원인: 수면 부족, 과도한 컨텍스트 스위칭, 성취감 없는 작업 반복. 에너지가 높았던 날과 비교해보세요.",
            createdAt: Date(),
            isResolved: false
        )
    }
    
    // MARK: - Keyword Patterns
    static func analyzeKeywordPatterns(_ entries: [ReflectionEntry]) -> [DiscoveredPattern] {
        let stopWords: Set<String> = ["그리고","하지만","그래서","이것","저것","그것","오늘","내가","나는","것이","하는","있는","없는","같은","하고","있다","없다","했다","되는","하면","해서","인데","으로","에서","까지","부터","이다","것은","것을","나도","내일","어제","좀","더","잘","못","수","거","게","건","걸","를","을","는","은","이","가","에","도","의","과","와","로","며","고","면","때","번","중","날","것","한","안","그","저","이런","저런","그런","뭔가","어떤","이걸","그걸"]
        
        var wordFreq: [String: [ReflectionEntry]] = [:]
        
        for entry in entries.prefix(15) {
            let allText = entry.answers.map { $0.answer }.joined(separator: " ")
            let words = allText.components(separatedBy: .alphanumerics.inverted)
                .filter { $0.count >= 2 && !stopWords.contains($0) }
            let unique = Set(words)
            for word in unique {
                wordFreq[word, default: []].append(entry)
            }
        }
        
        return wordFreq
            .filter { $0.value.count >= 4 && $0.key.count >= 2 }
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { word, items in
                DiscoveredPattern(
                    id: "word_\(word)",
                    type: .keywordPattern,
                    name: "\"\(word)\" 키워드가 반복 등장",
                    description: "최근 15회 회고 중 \(items.count)회에서 \"\(word)\"가 등장합니다.",
                    frequency: items.count,
                    severity: items.count >= 6 ? .mid : .low,
                    evidence: items.prefix(4).map { e in
                        let text = e.answers.map { $0.answer }.joined(separator: " ")
                        if let range = text.range(of: word) {
                            let start = text.index(max(text.startIndex, text.index(range.lowerBound, offsetBy: -15, limitedBy: text.startIndex) ?? text.startIndex), offsetBy: 0)
                            let end = text.index(min(text.endIndex, text.index(range.upperBound, offsetBy: 30, limitedBy: text.endIndex) ?? text.endIndex), offsetBy: 0)
                            return PatternEvidence(date: e.date, excerpt: "..." + String(text[start..<end]) + "...")
                        }
                        return PatternEvidence(date: e.date, excerpt: text.prefix(60) + "...")
                    },
                    insight: "반복되는 키워드는 무의식이 보내는 신호일 수 있습니다. \"\(word)\"에 대해 깊이 생각해볼 시간을 가져보세요.",
                    createdAt: Date(),
                    isResolved: false
                )
            }
    }
    
    // MARK: - Question Patterns
    static func analyzeQuestionPatterns(_ entries: [ReflectionEntry]) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        
        // Find questions that are consistently answered (or consistently skipped)
        let recent = Array(entries.prefix(10))
        guard recent.count >= 5 else { return [] }
        
        // "다시 반복하고 싶지 않은 일" 질문에 매번 답변이 있으면 패턴
        let neverAgainAnswers = recent.compactMap { entry in
            entry.answers.first(where: { $0.questionId == "never_again" && !$0.answer.isEmpty })
        }
        
        if neverAgainAnswers.count >= 4 {
            patterns.append(DiscoveredPattern(
                id: "q_never_again_frequent",
                type: .questionPattern,
                name: "반복하기 싫은 일이 계속 생김",
                description: "최근 \(recent.count)회 회고 중 \(neverAgainAnswers.count)회에서 '반복하고 싶지 않은 일'에 답변했습니다. 같은 유형의 불만이 반복되고 있을 수 있습니다.",
                frequency: neverAgainAnswers.count,
                severity: .mid,
                evidence: neverAgainAnswers.prefix(4).map { PatternEvidence(date: Date(), excerpt: String($0.answer.prefix(80)) + "...") },
                insight: "매번 반복하기 싫다고 느끼는 일이 있다면, 그것을 '피하는 것'이 아니라 '구조적으로 제거'할 방법을 고민해보세요. 프로세스 변경, 위임, 자동화 등.",
                createdAt: Date(),
                isResolved: false
            ))
        }
        
        // 에너지 드레인 질문에 계속 답변
        let energyDrainAnswers = recent.compactMap { entry in
            entry.answers.first(where: { $0.questionId == "energy_drain" && !$0.answer.isEmpty })
        }
        
        if energyDrainAnswers.count >= 4 {
            patterns.append(DiscoveredPattern(
                id: "q_energy_drain_frequent",
                type: .questionPattern,
                name: "에너지 소모 요인이 지속적으로 존재",
                description: "최근 \(recent.count)회 회고 중 \(energyDrainAnswers.count)회에서 에너지가 빠지는 순간을 보고했습니다.",
                frequency: energyDrainAnswers.count,
                severity: energyDrainAnswers.count >= 6 ? .high : .mid,
                evidence: energyDrainAnswers.prefix(4).map { PatternEvidence(date: Date(), excerpt: String($0.answer.prefix(80)) + "...") },
                insight: "에너지를 소모하는 요인이 계속 있다면, 그 요인을 줄이거나 에너지를 회복하는 루틴을 의도적으로 배치해보세요.",
                createdAt: Date(),
                isResolved: false
            ))
        }
        
        return patterns
    }
    
    // MARK: - Time Patterns
    static func analyzeTimePatterns(_ entries: [ReflectionEntry]) -> [DiscoveredPattern] {
        let negativeEmojis: Set<String> = ["😤", "😔", "😰", "😮‍💨"]
        
        var periodData: [String: (count: Int, negEmotion: Int, lowEnergy: Int)] = [:]
        
        for entry in entries {
            let hour = Calendar.current.component(.hour, from: entry.date)
            let period = hour < 6 ? "새벽" : hour < 12 ? "오전" : hour < 18 ? "오후" : "밤"
            var data = periodData[period] ?? (0, 0, 0)
            data.count += 1
            if negativeEmojis.contains(entry.emotion) { data.negEmotion += 1 }
            if entry.energyLevel > 0 && entry.energyLevel <= 3 { data.lowEnergy += 1 }
            periodData[period] = data
        }
        
        return periodData.compactMap { period, data -> DiscoveredPattern? in
            guard data.count >= 3 else { return nil }
            let negRatio = Double(data.negEmotion) / Double(data.count)
            let lowRatio = Double(data.lowEnergy) / Double(data.count)
            guard negRatio >= 0.6 || lowRatio >= 0.5 else { return nil }
            
            return DiscoveredPattern(
                id: "time_\(period)",
                type: .timePattern,
                name: "\(period) 시간대에 부정적 상태 집중",
                description: "\(period)에 작성된 \(data.count)개의 회고 중 부정 감정 \(data.negEmotion)회, 낮은 에너지 \(data.lowEnergy)회가 관찰됩니다.",
                frequency: data.count,
                severity: .mid,
                evidence: [],
                insight: "\(period) 시간대에 특히 힘든 패턴이 보입니다. 이 시간대의 활동, 환경, 루틴을 점검해보세요.",
                createdAt: Date(),
                isResolved: false
            )
        }
    }
    
    // MARK: - Positive Pattern
    static func analyzePositivePattern(_ entries: [ReflectionEntry]) -> DiscoveredPattern? {
        let positiveEmojis: Set<String> = ["😊", "🔥", "💡", "😌"]
        let positiveEntries = entries.filter { positiveEmojis.contains($0.emotion) || $0.energyLevel >= 7 }
        guard positiveEntries.count >= 3 else { return nil }
        
        var tagCounts: [String: Int] = [:]
        positiveEntries.forEach { $0.tags.forEach { tagCounts[$0, default: 0] += 1 } }
        
        guard let topTag = tagCounts.max(by: { $0.value < $1.value }), topTag.value >= 2 else { return nil }
        
        return DiscoveredPattern(
            id: "positive_\(topTag.key)",
            type: .positivePattern,
            name: "\"\(topTag.key)\" 영역에서 에너지를 얻음",
            description: "긍정적 감정이나 높은 에너지를 보인 \(positiveEntries.count)개 회고 중 \(topTag.value)개가 \"\(topTag.key)\"와 연관됩니다.",
            frequency: topTag.value,
            severity: .positive,
            evidence: positiveEntries.filter { $0.tags.contains(topTag.key) }.prefix(3).map {
                PatternEvidence(date: $0.date, excerpt: $0.answers.first(where: { !$0.answer.isEmpty })?.answer.prefix(80).appending("...") ?? "")
            },
            insight: "이 영역에 더 많은 시간과 에너지를 투자할 방법을 고민해보세요. 강점을 살리는 것이 약점을 보완하는 것보다 효과적인 경우가 많습니다.",
            createdAt: Date(),
            isResolved: false
        )
    }

    // MARK: - ⭐️ Causal Relationship Analysis
    static func analyzeCausalRelationships(patterns: [DiscoveredPattern]) -> [DiscoveredPattern] {
        guard patterns.count >= 2 else { return patterns }

        var updatedPatterns = patterns

        // 1. 패턴 간 상관관계 계산
        let correlations = calculateCorrelations(patterns: patterns)

        // 2. 각 패턴에 대해 원인-증상 분석
        for i in updatedPatterns.indices {
            let pattern = updatedPatterns[i]
            let relatedPatterns = correlations.filter { $0.pattern1Id == pattern.id || $0.pattern2Id == pattern.id }

            // 3. 타입별 우선순위로 원인/증상 분류
            let (causes, symptoms) = classifyCausesAndSymptoms(
                forPattern: pattern,
                relatedPatterns: relatedPatterns,
                allPatterns: patterns
            )

            // 4. 패턴 업데이트
            updatedPatterns[i].possibleCauses = causes.isEmpty ? nil : causes
            updatedPatterns[i].symptoms = symptoms.isEmpty ? nil : symptoms
            updatedPatterns[i].relatedPatternIds = relatedPatterns.isEmpty ? nil : relatedPatterns.map {
                $0.pattern1Id == pattern.id ? $0.pattern2Id : $0.pattern1Id
            }
            updatedPatterns[i].correlationScore = relatedPatterns.isEmpty ? nil :
                relatedPatterns.map { $0.score }.reduce(0, +) / Double(relatedPatterns.count)
        }

        return updatedPatterns
    }

    // 상관관계 계산
    struct PatternCorrelation {
        let pattern1Id: String
        let pattern2Id: String
        let score: Double  // 0.0 ~ 1.0
        let sharedDates: Int
    }

    static func calculateCorrelations(patterns: [DiscoveredPattern]) -> [PatternCorrelation] {
        var correlations: [PatternCorrelation] = []

        // 모든 패턴 조합에 대해 상관관계 계산
        for i in 0..<patterns.count {
            for j in (i+1)..<patterns.count {
                let p1 = patterns[i]
                let p2 = patterns[j]

                // 날짜 기반 상관도 계산 (Jaccard similarity)
                let dates1 = Set(p1.evidence.map { Calendar.current.startOfDay(for: $0.date) })
                let dates2 = Set(p2.evidence.map { Calendar.current.startOfDay(for: $0.date) })

                let intersection = dates1.intersection(dates2).count
                let union = dates1.union(dates2).count

                guard union > 0, intersection >= 2 else { continue }

                let jaccardScore = Double(intersection) / Double(union)

                // 상관도가 0.3 이상인 경우만 의미있다고 판단
                if jaccardScore >= 0.3 {
                    correlations.append(PatternCorrelation(
                        pattern1Id: p1.id,
                        pattern2Id: p2.id,
                        score: jaccardScore,
                        sharedDates: intersection
                    ))
                }
            }
        }

        return correlations.sorted { $0.score > $1.score }
    }

    // 원인-증상 분류
    static func classifyCausesAndSymptoms(
        forPattern pattern: DiscoveredPattern,
        relatedPatterns: [PatternCorrelation],
        allPatterns: [DiscoveredPattern]
    ) -> (causes: [String], symptoms: [String]) {

        // 패턴 타입별 우선순위
        // 원인 가능성: keyword > recurringTheme > questionPattern > timePattern
        // 증상 가능성: emotion > energy > questionPattern

        let causePriority: [PatternType: Int] = [
            .keywordPattern: 4,      // 가장 구체적 (예: "회의")
            .recurringTheme: 3,      // 반복되는 주제/태그
            .questionPattern: 2,     // 특정 질문 반복
            .timePattern: 1          // 시간대 패턴
        ]

        let symptomPriority: [PatternType: Int] = [
            .emotionPattern: 4,      // 감정 변화
            .energyPattern: 3,       // 에너지 저하
            .questionPattern: 2      // 불만 반복
        ]

        var causes: [String] = []
        var symptoms: [String] = []

        for correlation in relatedPatterns {
            let otherId = correlation.pattern1Id == pattern.id ? correlation.pattern2Id : correlation.pattern1Id
            guard let otherPattern = allPatterns.first(where: { $0.id == otherId }) else { continue }

            let myPriority = causePriority[pattern.type] ?? 0
            let otherPriority = causePriority[otherPattern.type] ?? 0

            // 상대방이 나보다 원인 우선순위가 높으면 → 상대방이 원인, 나는 증상
            if otherPriority > myPriority {
                if symptomPriority[pattern.type] ?? 0 > 0 {
                    // 나는 증상으로 분류될 수 있는 타입
                    causes.append(otherPattern.name)
                }
            }
            // 내가 원인 우선순위가 높으면 → 나는 원인, 상대방이 증상
            else if myPriority > otherPriority {
                if symptomPriority[otherPattern.type] ?? 0 > 0 {
                    symptoms.append(otherPattern.name)
                }
            }
            // 같은 우선순위면 증상끼리의 관계일 수도
            else {
                // 둘 다 증상 타입이면 공통 원인 가능성 힌트
                if symptomPriority[pattern.type] ?? 0 > 0 && symptomPriority[otherPattern.type] ?? 0 > 0 {
                    // 공통 원인을 찾아야 함 (현재는 표시만)
                }
            }
        }

        return (Array(Set(causes)), Array(Set(symptoms)))
    }
}
