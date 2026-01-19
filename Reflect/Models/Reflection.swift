import Foundation
import SwiftData

@Model
final class Reflection {
    var id: UUID
    var date: Date
    var wentWell: String           // 잘한 것
    var couldImprove: String       // 개선할 점
    var nextAction: String         // 다음 액션
    var gratitude: String          // 감사한 것
    var energyLevel: Int           // 에너지 레벨 (1-5)
    var moodScore: Int             // 기분 점수 (1-5)
    var learnings: String          // 오늘 배운 것
    var isCompleted: Bool          // 완료 여부
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        wentWell: String = "",
        couldImprove: String = "",
        nextAction: String = "",
        gratitude: String = "",
        energyLevel: Int = 3,
        moodScore: Int = 3,
        learnings: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.wentWell = wentWell
        self.couldImprove = couldImprove
        self.nextAction = nextAction
        self.gratitude = gratitude
        self.energyLevel = energyLevel
        self.moodScore = moodScore
        self.learnings = learnings
        self.isCompleted = isCompleted
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    var completionScore: Double {
        var score = 0.0
        if !wentWell.isEmpty { score += 1 }
        if !couldImprove.isEmpty { score += 1 }
        if !nextAction.isEmpty { score += 1 }
        if !gratitude.isEmpty { score += 1 }
        if !learnings.isEmpty { score += 1 }
        return score / 5.0
    }
}

// MARK: - Sample Data
extension Reflection {
    static var sampleData: [Reflection] {
        let calendar = Calendar.current
        return [
            Reflection(
                date: calendar.date(byAdding: .day, value: -6, to: Date())!,
                wentWell: "새로운 SwiftUI 애니메이션 기법을 배웠다",
                couldImprove: "집중 시간이 짧았다",
                nextAction: "포모도로 기법 적용하기",
                gratitude: "좋은 날씨",
                energyLevel: 4,
                moodScore: 4,
                learnings: "withAnimation의 다양한 옵션들",
                isCompleted: true
            ),
            Reflection(
                date: calendar.date(byAdding: .day, value: -5, to: Date())!,
                wentWell: "포모도로 기법으로 3시간 집중",
                couldImprove: "운동을 건너뛰었다",
                nextAction: "내일은 아침 운동 필수",
                gratitude: "맛있는 점심",
                energyLevel: 3,
                moodScore: 4,
                learnings: "SwiftData 마이그레이션 방법",
                isCompleted: true
            ),
            Reflection(
                date: calendar.date(byAdding: .day, value: -4, to: Date())!,
                wentWell: "아침 운동 성공, 하루 종일 에너지 좋음",
                couldImprove: "SNS에 시간을 너무 많이 썼다",
                nextAction: "스크린 타임 제한 설정",
                gratitude: "건강한 몸",
                energyLevel: 5,
                moodScore: 5,
                learnings: "운동이 에너지에 미치는 영향",
                isCompleted: true
            ),
            Reflection(
                date: calendar.date(byAdding: .day, value: -3, to: Date())!,
                wentWell: "앱 핵심 기능 구현 완료",
                couldImprove: "코드 리뷰 시간이 부족했다",
                nextAction: "매일 30분 코드 리뷰 시간 확보",
                gratitude: "문제 해결의 즐거움",
                energyLevel: 4,
                moodScore: 4,
                learnings: "MVVM 패턴의 실제 적용",
                isCompleted: true
            ),
            Reflection(
                date: calendar.date(byAdding: .day, value: -2, to: Date())!,
                wentWell: "코드 리뷰로 버그 3개 발견",
                couldImprove: "회의가 너무 길었다",
                nextAction: "회의 시간 제한 제안하기",
                gratitude: "팀원들의 협력",
                energyLevel: 3,
                moodScore: 3,
                learnings: "코드 리뷰의 중요성",
                isCompleted: true
            ),
            Reflection(
                date: calendar.date(byAdding: .day, value: -1, to: Date())!,
                wentWell: "회의 시간 단축 성공",
                couldImprove: "저녁에 피곤해서 학습 못함",
                nextAction: "아침 시간 활용해서 학습하기",
                gratitude: "효율적인 하루",
                energyLevel: 3,
                moodScore: 4,
                learnings: "시간 관리의 중요성",
                isCompleted: true
            )
        ]
    }
}
