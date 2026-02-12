import Foundation
import SwiftUI

// MARK: - Reflection Entry
struct ReflectionEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var answers: [QuestionAnswer]
    var tags: [String]
    var emotion: String
    var energyLevel: Int // 1-10
    
    init(answers: [QuestionAnswer], tags: [String], emotion: String, energyLevel: Int) {
        self.id = UUID()
        self.date = Date()
        self.answers = answers
        self.tags = tags
        self.emotion = emotion
        self.energyLevel = energyLevel
    }
}

struct QuestionAnswer: Codable, Identifiable {
    let id: UUID
    let questionId: String
    let question: String
    var answer: String
    
    init(questionId: String, question: String, answer: String = "") {
        self.id = UUID()
        self.questionId = questionId
        self.question = question
        self.answer = answer
    }
}

// MARK: - Reflection Questions
struct ReflectionQuestion: Identifiable {
    let id: String
    let emoji: String
    let question: String
    let placeholder: String
    let category: QuestionCategory
}

enum QuestionCategory: String, CaseIterable {
    case pride = "자랑스러움"
    case avoidance = "반복 방지"
    case growth = "성장"
    case energy = "에너지"
    case relationship = "관계"
    case awareness = "인지"
}

let reflectionQuestions: [ReflectionQuestion] = [
    ReflectionQuestion(
        id: "proud_moment",
        emoji: "🏆",
        question: "오늘 하루 중 너무나 뿌듯한 순간이 있었나요?\n그렇다면 언제였나요?",
        placeholder: "작은 성취도 좋아요. 어떤 순간이었는지 떠올려보세요...",
        category: .pride
    ),
    ReflectionQuestion(
        id: "never_again",
        emoji: "🚫",
        question: "다시 반복하고 싶지 않은 일이 있었나요?\n그렇다면 어떤 건가요?",
        placeholder: "불편했던 상황, 후회되는 선택, 시간 낭비...",
        category: .avoidance
    ),
    ReflectionQuestion(
        id: "self_praise",
        emoji: "⭐",
        question: "스스로 자랑스러운 순간이 있었나요?\n그렇다면 언제인가요?",
        placeholder: "남들은 모를 수 있지만, 나만 아는 나의 대단한 순간...",
        category: .pride
    ),
    ReflectionQuestion(
        id: "energy_drain",
        emoji: "🔋",
        question: "에너지가 확 빠지는 순간이 있었나요?\n무엇이 그렇게 만들었나요?",
        placeholder: "어떤 사람, 상황, 업무가 에너지를 가져갔나요?",
        category: .energy
    ),
    ReflectionQuestion(
        id: "energy_charge",
        emoji: "⚡",
        question: "반대로 에너지가 확 차오른 순간은요?\n무엇이 나를 충전시켰나요?",
        placeholder: "신나는 대화, 몰입했던 작업, 좋은 소식...",
        category: .energy
    ),
    ReflectionQuestion(
        id: "kept_postponing",
        emoji: "⏰",
        question: "계속 미루고 있는 것이 있나요?\n왜 미루게 되는 걸까요?",
        placeholder: "미루는 이유를 솔직하게 적어보세요...",
        category: .awareness
    ),
    ReflectionQuestion(
        id: "surprised_self",
        emoji: "😲",
        question: "오늘 나 자신에 대해 새롭게 알게 된 것이 있나요?",
        placeholder: "예상 못한 반응, 새로운 취향, 의외의 감정...",
        category: .growth
    ),
    ReflectionQuestion(
        id: "relationship_moment",
        emoji: "🤝",
        question: "누군가와의 관계에서 인상 깊었던 순간이 있나요?",
        placeholder: "감사했던 것, 서운했던 것, 깊어진 대화...",
        category: .relationship
    ),
    ReflectionQuestion(
        id: "if_redo",
        emoji: "🔄",
        question: "오늘을 다시 살 수 있다면\n딱 하나 바꾸고 싶은 것은?",
        placeholder: "하나만 바꾼다면 무엇을 어떻게?",
        category: .avoidance
    ),
    ReflectionQuestion(
        id: "body_signal",
        emoji: "🧘",
        question: "몸이 보낸 신호가 있었나요?\n(피곤함, 통증, 긴장 등)",
        placeholder: "어깨가 뻣뻣, 눈이 피로, 소화가 안 됐다...",
        category: .awareness
    ),
    ReflectionQuestion(
        id: "decision_made",
        emoji: "🎯",
        question: "오늘 내린 결정 중\n가장 중요했던 것은 무엇인가요?",
        placeholder: "크든 작든, 의미 있었던 선택...",
        category: .growth
    ),
    ReflectionQuestion(
        id: "gratitude",
        emoji: "🙏",
        question: "오늘 감사한 것이 있다면\n무엇인가요?",
        placeholder: "당연하다고 넘겼지만, 사실 감사한 것...",
        category: .growth
    ),
]

// MARK: - Pattern
struct DiscoveredPattern: Codable, Identifiable {
    let id: String
    let type: PatternType
    let name: String
    let description: String
    let frequency: Int
    let severity: PatternSeverity
    let evidence: [PatternEvidence]
    let insight: String
    let createdAt: Date
    var isResolved: Bool
    var resolvedAt: Date?

    // Causal relationship analysis
    var possibleCauses: [String]?        // 이 패턴의 가능한 원인들
    var symptoms: [String]?              // 이 패턴으로 인한 증상들
    var relatedPatternIds: [String]?     // 연관된 패턴 ID들
    var correlationScore: Double?        // 연관성 점수 (0.0-1.0)
}

enum PatternType: String, Codable {
    case recurringTheme = "recurring_theme"
    case emotionPattern = "emotion_pattern"
    case energyPattern = "energy_pattern"
    case keywordPattern = "keyword_pattern"
    case timePattern = "time_pattern"
    case positivePattern = "positive_pattern"
    case questionPattern = "question_pattern"
}

enum PatternSeverity: String, Codable {
    case high, mid, low, positive
    
    var color: Color {
        switch self {
        case .high: return .red
        case .mid: return .orange
        case .low: return .blue
        case .positive: return .green
        }
    }
    
    var label: String {
        switch self {
        case .high: return "주의 필요"
        case .mid: return "관찰 중"
        case .low: return "참고"
        case .positive: return "강점"
        }
    }
}

struct PatternEvidence: Codable {
    let date: Date
    let excerpt: String
}

// MARK: - Emotions
struct Emotion: Identifiable {
    let id: String
    let emoji: String
    let label: String
    let isNegative: Bool
}

let emotions: [Emotion] = [
    Emotion(id: "frustrated", emoji: "😤", label: "답답", isNegative: true),
    Emotion(id: "sad", emoji: "😔", label: "우울", isNegative: true),
    Emotion(id: "anxious", emoji: "😰", label: "불안", isNegative: true),
    Emotion(id: "tired", emoji: "😮‍💨", label: "지침", isNegative: true),
    Emotion(id: "neutral", emoji: "😐", label: "무감각", isNegative: false),
    Emotion(id: "thinking", emoji: "🤔", label: "고민", isNegative: false),
    Emotion(id: "calm", emoji: "😌", label: "평온", isNegative: false),
    Emotion(id: "happy", emoji: "😊", label: "기쁨", isNegative: false),
    Emotion(id: "fire", emoji: "🔥", label: "열정", isNegative: false),
    Emotion(id: "insight", emoji: "💡", label: "깨달음", isNegative: false),
]

// MARK: - Tags
let defaultTags = ["업무", "의사결정", "관계", "건강", "시간관리", "감정", "학습", "습관", "돈", "에너지", "창작", "루틴"]
