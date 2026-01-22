import Foundation
import SwiftData

// MARK: - 병목 지점 엔트리 (Bottleneck Entry)
/// 일일 회고에서 기록되는 개별 병목 지점
@Model
final class BottleneckEntry {
    var id: UUID
    var createdAt: Date                    // 생성 날짜
    var taskName: String                   // 작업명
    var estimatedMinutes: Int              // 예상 소요 시간 (분)
    var actualMinutes: Int                 // 실제 소요 시간 (분)
    var delayReason: String                // 지연 원인 (자유 텍스트)
    var weeklyFrequency: Int               // 이번 주 반복 횟수
    var automationScore: Int               // 도구화 가능성 점수 (1-5)
    var tags: [String]                     // 태그 배열 (#데이터처리, #문서작업 등)
    var notes: String                      // 추가 메모

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        taskName: String = "",
        estimatedMinutes: Int = 0,
        actualMinutes: Int = 0,
        delayReason: String = "",
        weeklyFrequency: Int = 1,
        automationScore: Int = 3,
        tags: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.taskName = taskName
        self.estimatedMinutes = estimatedMinutes
        self.actualMinutes = actualMinutes
        self.delayReason = delayReason
        self.weeklyFrequency = weeklyFrequency
        self.automationScore = automationScore
        self.tags = tags
        self.notes = notes
    }

    // MARK: - Computed Properties

    /// 낭비된 시간 (실제 - 예상)
    var wastedMinutes: Int {
        max(0, actualMinutes - estimatedMinutes)
    }

    /// 주간 총 낭비 시간 (낭비 시간 × 빈도)
    var weeklyWastedMinutes: Int {
        wastedMinutes * weeklyFrequency
    }

    /// 간단한 ROI 점수 (도구화 가능성 × 주간 낭비 시간)
    var roiScore: Double {
        Double(automationScore) * Double(weeklyWastedMinutes)
    }

    /// 날짜 포맷팅 (한국어)
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: createdAt)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: createdAt)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }

    /// 태그 문자열 (쉼표 구분)
    var tagsString: String {
        get { tags.joined(separator: ", ") }
        set {
            tags = newValue
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
    }

    /// 자동화 점수 이모지
    var automationEmoji: String {
        switch automationScore {
        case 1: return "⚪️"
        case 2: return "🔵"
        case 3: return "🟡"
        case 4: return "🟠"
        case 5: return "🔴"
        default: return "⚪️"
        }
    }

    /// 시간 포맷팅 (분 → 시간:분)
    static func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)분"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)시간 \(mins)분" : "\(hours)시간"
        }
    }
}

// MARK: - 도구 개발 트래커 (Tool Development Tracker)
/// 개발 중인 자동화 도구 추적
@Model
final class ToolDevelopment {
    var id: UUID
    var toolName: String                   // 도구명
    var targetBottleneck: String           // 목표 병목 지점 설명
    var status: String                     // 상태: planning, developing, completed, abandoned
    var startDate: Date?                   // 개발 시작일
    var completedDate: Date?               // 완료일
    var estimatedDevMinutes: Int           // 예상 개발 시간 (분)
    var actualDevMinutes: Int              // 실제 개발 시간 (분)
    var expectedSavingMinutes: Int         // 예상 절감 시간 (분/주)
    var actualSavingMinutes: Int           // 실제 절감 시간 (분/주)
    var notes: String

    init(
        id: UUID = UUID(),
        toolName: String = "",
        targetBottleneck: String = "",
        status: String = "planning",
        startDate: Date? = nil,
        completedDate: Date? = nil,
        estimatedDevMinutes: Int = 0,
        actualDevMinutes: Int = 0,
        expectedSavingMinutes: Int = 0,
        actualSavingMinutes: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.toolName = toolName
        self.targetBottleneck = targetBottleneck
        self.status = status
        self.startDate = startDate
        self.completedDate = completedDate
        self.estimatedDevMinutes = estimatedDevMinutes
        self.actualDevMinutes = actualDevMinutes
        self.expectedSavingMinutes = expectedSavingMinutes
        self.actualSavingMinutes = actualSavingMinutes
        self.notes = notes
    }

    /// 상태 아이콘
    var statusIcon: String {
        switch status {
        case "planning": return "📋"
        case "developing": return "🔨"
        case "completed": return "✅"
        case "abandoned": return "❌"
        default: return "📋"
        }
    }

    /// 상태 한국어 표시
    var statusText: String {
        switch status {
        case "planning": return "계획중"
        case "developing": return "개발중"
        case "completed": return "완료"
        case "abandoned": return "폐기"
        default: return "계획중"
        }
    }

    /// ROI 계산 (주 단위)
    /// (예상 절감 시간 × 52주) / 개발 시간
    var calculatedROI: Double {
        guard actualDevMinutes > 0 else { return 0 }
        let annualSaving = Double(actualSavingMinutes > 0 ? actualSavingMinutes : expectedSavingMinutes) * 52
        return annualSaving / Double(actualDevMinutes > 0 ? actualDevMinutes : estimatedDevMinutes)
    }
}

// MARK: - 목표 (Goal)
/// 주간/월간 목표 설정 및 추적 + 회고
@Model
final class Goal {
    var id: UUID
    var createdAt: Date
    var title: String                      // 목표 제목
    var goalDescription: String            // 목표 상세 설명
    var category: String                   // 카테고리: productivity, automation, learning, process
    var targetDate: Date?                  // 목표 달성 기한
    var isCompleted: Bool                  // 완료 여부
    var completedAt: Date?                 // 완료 일시
    var priority: Int                      // 우선순위 (1-3, 1이 가장 높음)
    var relatedTags: [String]              // 관련 태그 (병목 지점과 연결)
    var progressNotes: String              // 진행 상황 메모

    // MARK: - 회고 단계 (Stage)
    var currentStage: String               // setting, execution, reflection, completed

    // MARK: - 1단계: 목표 설정 (Setting)
    var whyImportant: String               // 왜 이 목표가 중요한가요?
    var expectedChange: String             // 목표 달성하면 어떤 변화가 있을까요?
    var successCriteria: String            // 목표 달성을 어떻게 측정할 수 있나요?

    // MARK: - 2단계: 실행 (Execution)
    var progressPercentage: Int            // 진행률 (0-100)
    var executionLogs: [String]            // 실행 기록 (JSON 인코딩된 로그들)

    // MARK: - 3단계: 회고 (Reflection)
    var whatWentWell: String               // 잘 된 점은 무엇인가요?
    var whatCouldImprove: String           // 아쉬운 점은 무엇인가요?
    var lessonsLearned: String             // 배운 점은 무엇인가요?
    var nextActions: String                // 다음에 다르게 하고 싶은 것은?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String = "",
        goalDescription: String = "",
        category: String = "productivity",
        targetDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        priority: Int = 2,
        relatedTags: [String] = [],
        progressNotes: String = "",
        currentStage: String = "setting",
        whyImportant: String = "",
        expectedChange: String = "",
        successCriteria: String = "",
        progressPercentage: Int = 0,
        executionLogs: [String] = [],
        whatWentWell: String = "",
        whatCouldImprove: String = "",
        lessonsLearned: String = "",
        nextActions: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.goalDescription = goalDescription
        self.category = category
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.priority = priority
        self.relatedTags = relatedTags
        self.progressNotes = progressNotes
        self.currentStage = currentStage
        self.whyImportant = whyImportant
        self.expectedChange = expectedChange
        self.successCriteria = successCriteria
        self.progressPercentage = progressPercentage
        self.executionLogs = executionLogs
        self.whatWentWell = whatWentWell
        self.whatCouldImprove = whatCouldImprove
        self.lessonsLearned = lessonsLearned
        self.nextActions = nextActions
    }

    /// 카테고리 아이콘
    var categoryIcon: String {
        switch category {
        case "productivity": return "bolt.fill"
        case "automation": return "gearshape.2.fill"
        case "learning": return "book.fill"
        case "process": return "arrow.triangle.2.circlepath"
        default: return "target"
        }
    }

    /// 카테고리 한국어
    var categoryText: String {
        switch category {
        case "productivity": return "생산성"
        case "automation": return "자동화"
        case "learning": return "학습"
        case "process": return "프로세스"
        default: return "기타"
        }
    }

    /// 우선순위 색상
    var priorityColor: String {
        switch priority {
        case 1: return "red"
        case 2: return "orange"
        case 3: return "blue"
        default: return "gray"
        }
    }

    /// 남은 일수
    var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: targetDate).day
        return days
    }

    /// 기한 상태
    var deadlineStatus: String {
        guard let days = daysRemaining else { return "기한 없음" }
        if days < 0 { return "기한 초과" }
        if days == 0 { return "오늘까지" }
        if days == 1 { return "내일까지" }
        return "\(days)일 남음"
    }

    /// 현재 단계 아이콘
    var stageIcon: String {
        switch currentStage {
        case "setting": return "1.circle.fill"
        case "execution": return "2.circle.fill"
        case "reflection": return "3.circle.fill"
        case "completed": return "checkmark.circle.fill"
        default: return "circle"
        }
    }

    /// 현재 단계 텍스트
    var stageText: String {
        switch currentStage {
        case "setting": return "목표 설정"
        case "execution": return "실행 중"
        case "reflection": return "회고"
        case "completed": return "완료"
        default: return "시작 전"
        }
    }

    /// 현재 단계 색상
    var stageColor: String {
        switch currentStage {
        case "setting": return "blue"
        case "execution": return "orange"
        case "reflection": return "purple"
        case "completed": return "green"
        default: return "gray"
        }
    }

    /// 목표 설정 완료 여부
    var isSettingComplete: Bool {
        !title.isEmpty && !whyImportant.isEmpty && !successCriteria.isEmpty
    }

    /// 회고 완료 여부
    var isReflectionComplete: Bool {
        !whatWentWell.isEmpty && !lessonsLearned.isEmpty
    }
}

// MARK: - 5분 회고 (Daily Retrospective)
/// 매일 기록하는 간단한 회고
@Model
final class DailyRetrospective {
    var id: UUID
    var date: Date                         // 회고 날짜 (날짜만, 하루에 하나)
    var good: String                       // 잘된 것
    var bad: String                        // 아쉬운 것
    var ideas: String                      // 개선 아이디어
    var actions: String                    // 당장 실행할 것
    var createdAt: Date
    var updatedAt: Date

    // MARK: - 에너지 레벨
    var energyLevel: Int                   // 1-5 (1: 매우 낮음, 5: 매우 높음)

    // MARK: - 어제 액션 리뷰
    var previousActionsStatus: String      // none, completed, partial, skipped
    var previousActionsReview: String      // 어제 액션에 대한 회고/코멘트

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        good: String = "",
        bad: String = "",
        ideas: String = "",
        actions: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        energyLevel: Int = 3,
        previousActionsStatus: String = "none",
        previousActionsReview: String = ""
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.good = good
        self.bad = bad
        self.ideas = ideas
        self.actions = actions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.energyLevel = energyLevel
        self.previousActionsStatus = previousActionsStatus
        self.previousActionsReview = previousActionsReview
    }

    /// 오늘 회고인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// 날짜 포맷팅
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }

    /// 작성 완료 여부 (하나라도 작성했으면 true)
    var hasContent: Bool {
        !good.isEmpty || !bad.isEmpty || !ideas.isEmpty || !actions.isEmpty
    }

    /// 완성도 (4개 섹션 중 몇 개 작성했는지)
    var completionCount: Int {
        var count = 0
        if !good.isEmpty { count += 1 }
        if !bad.isEmpty { count += 1 }
        if !ideas.isEmpty { count += 1 }
        if !actions.isEmpty { count += 1 }
        return count
    }

    /// 어제 액션 상태 아이콘
    var previousActionsStatusIcon: String {
        switch previousActionsStatus {
        case "completed": return "checkmark.circle.fill"
        case "partial": return "circle.lefthalf.filled"
        case "skipped": return "xmark.circle.fill"
        default: return "circle"
        }
    }

    /// 어제 액션 상태 텍스트
    var previousActionsStatusText: String {
        switch previousActionsStatus {
        case "completed": return "완료"
        case "partial": return "부분 완료"
        case "skipped": return "미완료"
        default: return "미확인"
        }
    }

    /// 어제 액션 상태 색상
    var previousActionsStatusColor: String {
        switch previousActionsStatus {
        case "completed": return "green"
        case "partial": return "orange"
        case "skipped": return "red"
        default: return "gray"
        }
    }

    /// 어제 액션 리뷰 완료 여부
    var hasPreviousActionsReview: Bool {
        previousActionsStatus != "none"
    }

    /// 에너지 레벨 이모지
    var energyEmoji: String {
        switch energyLevel {
        case 1: return "😫"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "🔥"
        default: return "😐"
        }
    }

    /// 에너지 레벨 텍스트
    var energyText: String {
        switch energyLevel {
        case 1: return "매우 낮음"
        case 2: return "낮음"
        case 3: return "보통"
        case 4: return "좋음"
        case 5: return "최고"
        default: return "보통"
        }
    }

    /// 에너지 레벨 색상
    var energyColor: String {
        switch energyLevel {
        case 1: return "red"
        case 2: return "orange"
        case 3: return "yellow"
        case 4: return "green"
        case 5: return "blue"
        default: return "gray"
        }
    }
}

// MARK: - 질문 로그 (Question Log)
/// 정보 검색에 소요된 시간 추적
@Model
final class QuestionLog {
    var id: UUID
    var createdAt: Date
    var question: String                   // 검색/질문 내용
    var searchMinutes: Int                 // 소요 시간 (분)
    var wasSearchedBefore: Bool            // 이전 검색 여부
    var infoLocation: String               // 정보 위치 메모
    var tags: [String]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        question: String = "",
        searchMinutes: Int = 0,
        wasSearchedBefore: Bool = false,
        infoLocation: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.question = question
        self.searchMinutes = searchMinutes
        self.wasSearchedBefore = wasSearchedBefore
        self.infoLocation = infoLocation
        self.tags = tags
    }
}

// MARK: - Sample Data
extension BottleneckEntry {
    static var sampleData: [BottleneckEntry] {
        let calendar = Calendar.current
        return [
            BottleneckEntry(
                createdAt: calendar.date(byAdding: .day, value: -6, to: Date())!,
                taskName: "CSV 데이터 정리",
                estimatedMinutes: 30,
                actualMinutes: 90,
                delayReason: "포맷이 일관되지 않아 수작업 필요",
                weeklyFrequency: 3,
                automationScore: 5,
                tags: ["데이터처리", "반복작업"],
                notes: "Python 스크립트로 자동화 가능"
            ),
            BottleneckEntry(
                createdAt: calendar.date(byAdding: .day, value: -5, to: Date())!,
                taskName: "회의록 작성",
                estimatedMinutes: 20,
                actualMinutes: 45,
                delayReason: "템플릿 찾는데 시간 소요",
                weeklyFrequency: 5,
                automationScore: 4,
                tags: ["문서작업", "커뮤니케이션"],
                notes: "회의록 템플릿 자동 생성 도구"
            ),
            BottleneckEntry(
                createdAt: calendar.date(byAdding: .day, value: -4, to: Date())!,
                taskName: "배포 프로세스",
                estimatedMinutes: 15,
                actualMinutes: 60,
                delayReason: "수동 체크리스트 확인",
                weeklyFrequency: 2,
                automationScore: 5,
                tags: ["개발", "배포"],
                notes: "CI/CD 파이프라인 구축 필요"
            ),
            BottleneckEntry(
                createdAt: calendar.date(byAdding: .day, value: -3, to: Date())!,
                taskName: "이메일 응답 정리",
                estimatedMinutes: 30,
                actualMinutes: 50,
                delayReason: "비슷한 질문에 반복 답변",
                weeklyFrequency: 7,
                automationScore: 3,
                tags: ["커뮤니케이션", "반복작업"],
                notes: "FAQ 문서화 또는 템플릿 필요"
            ),
            BottleneckEntry(
                createdAt: calendar.date(byAdding: .day, value: -2, to: Date())!,
                taskName: "로그 분석",
                estimatedMinutes: 20,
                actualMinutes: 40,
                delayReason: "로그 파일 위치 찾기 어려움",
                weeklyFrequency: 4,
                automationScore: 4,
                tags: ["데이터처리", "디버깅"],
                notes: "로그 집계 대시보드 필요"
            ),
            BottleneckEntry(
                createdAt: calendar.date(byAdding: .day, value: -1, to: Date())!,
                taskName: "테스트 데이터 생성",
                estimatedMinutes: 15,
                actualMinutes: 35,
                delayReason: "다양한 케이스 수동 생성",
                weeklyFrequency: 3,
                automationScore: 5,
                tags: ["개발", "테스트"],
                notes: "Faker 라이브러리 활용한 자동 생성기"
            )
        ]
    }
}

extension ToolDevelopment {
    static var sampleData: [ToolDevelopment] {
        [
            ToolDevelopment(
                toolName: "CSV 자동 정리기",
                targetBottleneck: "CSV 데이터 정리",
                status: "developing",
                startDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
                estimatedDevMinutes: 180,
                actualDevMinutes: 60,
                expectedSavingMinutes: 180,
                notes: "Python pandas 활용"
            ),
            ToolDevelopment(
                toolName: "회의록 템플릿 생성기",
                targetBottleneck: "회의록 작성",
                status: "planning",
                estimatedDevMinutes: 120,
                expectedSavingMinutes: 125,
                notes: "Notion API 연동 고려"
            )
        ]
    }
}

extension Goal {
    static var sampleData: [Goal] {
        let calendar = Calendar.current
        return [
            Goal(
                title: "반복 작업 3개 자동화하기",
                goalDescription: "가장 시간이 많이 소요되는 반복 작업 3개를 자동화 도구로 해결",
                category: "automation",
                targetDate: calendar.date(byAdding: .day, value: 14, to: Date()),
                priority: 1,
                relatedTags: ["데이터처리", "반복작업"],
                progressNotes: "CSV 정리 자동화 진행 중"
            ),
            Goal(
                title: "주간 낭비 시간 30% 감소",
                goalDescription: "현재 주간 낭비 시간 대비 30% 이상 절감",
                category: "productivity",
                targetDate: calendar.date(byAdding: .month, value: 1, to: Date()),
                priority: 2,
                relatedTags: [],
                progressNotes: ""
            ),
            Goal(
                title: "문서화 프로세스 개선",
                goalDescription: "회의록, 보고서 등 문서 작업 템플릿 정리",
                category: "process",
                targetDate: calendar.date(byAdding: .day, value: 7, to: Date()),
                priority: 2,
                relatedTags: ["문서작업"],
                progressNotes: "회의록 템플릿 초안 작성 완료"
            )
        ]
    }
}
