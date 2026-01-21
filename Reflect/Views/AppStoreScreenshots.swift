import SwiftUI
import SwiftData

// MARK: - 앱스토어 스크린샷 생성 View
struct AppStoreScreenshotView: View {
    let screenshotNumber: Int

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // 상단 텍스트
                VStack(spacing: 12) {
                    Text(headlines[screenshotNumber - 1].headline)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(headlines[screenshotNumber - 1].subheadline)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)

                // 앱 스크린샷 (목업)
                screenContent(for: screenshotNumber)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .frame(width: 1280, height: 800)
    }

    private var headlines: [(headline: String, subheadline: String)] {
        [
            ("하루 5분, 병목을 발견하다", "매일의 회고에서 숨겨진 비효율을 찾아냅니다"),
            ("시간 낭비, 한눈에 파악", "주간 분석으로 패턴을 시각화합니다"),
            ("기록하면 보이는 것들", "예상 vs 실제 시간, ROI까지 자동 계산"),
            ("자동화 우선순위, 명확하게", "ROI 기반으로 뭘 먼저 할지 알려드립니다"),
            ("당신의 시간을 되찾으세요", "macOS 네이티브 앱의 직관적인 UX")
        ]
    }

    @ViewBuilder
    private func screenContent(for number: Int) -> some View {
        switch number {
        case 1:
            Screenshot1_DailyReview()
        case 2:
            Screenshot2_Dashboard()
        case 3:
            Screenshot3_BottleneckInput()
        case 4:
            Screenshot4_AutomationPriority()
        case 5:
            Screenshot5_FullLayout()
        default:
            Screenshot1_DailyReview()
        }
    }
}

// MARK: - 스크린샷 1: 5분 회고 화면
struct Screenshot1_DailyReview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 윈도우 타이틀바
            MockWindowTitleBar(title: "돌아보기")

            HStack(spacing: 0) {
                // 사이드바
                MockSidebar(selected: "오늘 기록")
                    .frame(width: 200)

                Divider()

                // 메인 콘텐츠
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 헤더
                        VStack(alignment: .leading, spacing: 4) {
                            Text("좋은 아침이에요 ☀️")
                                .font(.title.bold())
                            Text("1월 21일 화요일")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        // 병목 인사이트 카드
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                Text("이번 주 병목 패턴")
                                    .font(.body.bold())
                                Spacer()
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "repeat")
                                    .foregroundStyle(.purple)
                                    .frame(width: 20)
                                Text("#데이터처리, #반복작업 관련 작업이 자주 발생해요")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "wand.and.stars")
                                    .foregroundStyle(.orange)
                                    .frame(width: 20)
                                Text("'CSV 정리' 자동화 시 주당 1시간 30분 절약 가능")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 6) {
                                Text("자주 나오는 태그:")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                TagPill(text: "#데이터처리")
                                TagPill(text: "#반복작업")
                                TagPill(text: "#문서작업")
                            }
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                        )

                        // 5분 회고 헤더
                        HStack {
                            Label("5분 회고", systemImage: "sparkles")
                                .font(.headline)
                            Spacer()
                            Button {} label: {
                                Label("저장", systemImage: "checkmark.circle.fill")
                                    .font(.body)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }

                        // 회고 입력 필드
                        VStack(spacing: 12) {
                            MockRetrospectiveRow(emoji: "😊", title: "Good", subtitle: "잘된 것", text: "API 리팩토링 성공적으로 완료")
                            MockRetrospectiveRow(emoji: "😞", title: "Bad", subtitle: "아쉬운 것", text: "CSV 정리에 또 1시간 넘게 소요")
                            MockRetrospectiveRow(emoji: "💡", title: "Ideas", subtitle: "개선 아이디어", text: "Python 스크립트로 자동화")
                            MockRetrospectiveRow(emoji: "⚡", title: "Actions", subtitle: "당장 실행할 것", text: "내일 오전에 자동화 스크립트 작성 시작")
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(24)
                }
                .frame(width: 500)
                .background(Color(.windowBackgroundColor))

                Divider()

                // 오른쪽 인스펙터
                MockQuickStats()
                    .frame(width: 280)
            }
        }
        .frame(width: 1000, height: 600)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - 스크린샷 2: 대시보드
struct Screenshot2_Dashboard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MockWindowTitleBar(title: "돌아보기")

            HStack(spacing: 0) {
                MockSidebar(selected: "대시보드")
                    .frame(width: 200)

                Divider()

                // 대시보드 콘텐츠
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 헤더
                        VStack(alignment: .leading, spacing: 8) {
                            Text("분석 대시보드")
                                .font(.title.bold())
                            Text("병목 지점을 분석하고 자동화 우선순위를 확인하세요")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        // 기간 선택
                        HStack(spacing: 8) {
                            MockPeriodButton(text: "1주일", isSelected: true)
                            MockPeriodButton(text: "1개월", isSelected: false)
                            MockPeriodButton(text: "전체", isSelected: false)
                            Spacer()
                        }

                        // 통계 카드
                        HStack(spacing: 16) {
                            MockStatCard(title: "기록 수", value: "12", subtitle: "개", icon: "doc.text.fill", color: .blue)
                            MockStatCard(title: "총 낭비 시간", value: "4시간 30분", subtitle: "", icon: "clock.badge.exclamationmark", color: .red)
                            MockStatCard(title: "주간 낭비", value: "6시간 15분", subtitle: "예상", icon: "calendar.badge.clock", color: .orange)
                            MockStatCard(title: "평균 도구화 점수", value: "3.8", subtitle: "/5", icon: "star.fill", color: .yellow)
                        }

                        // 차트 영역
                        HStack(spacing: 20) {
                            // 일별 낭비 시간 차트
                            VStack(alignment: .leading, spacing: 16) {
                                Label("일별 낭비 시간 추이", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.headline)

                                MockLineChart()
                                    .frame(height: 150)
                            }
                            .padding(20)
                            .background(Color(.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // 태그별 낭비 시간
                            VStack(alignment: .leading, spacing: 16) {
                                Label("태그별 낭비 시간", systemImage: "tag.fill")
                                    .font(.headline)

                                MockBarChart()
                                    .frame(height: 150)
                            }
                            .padding(20)
                            .background(Color(.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(24)
                }
                .background(Color(.windowBackgroundColor))
            }
        }
        .frame(width: 1000, height: 600)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - 스크린샷 3: 병목 지점 입력
struct Screenshot3_BottleneckInput: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MockWindowTitleBar(title: "돌아보기")

            HStack(spacing: 0) {
                MockSidebar(selected: "오늘 기록")
                    .frame(width: 200)

                Divider()

                // 메인 콘텐츠
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 병목 지점 섹션 헤더
                        HStack {
                            Label("병목 지점 기록", systemImage: "exclamationmark.triangle")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            Spacer()
                        }

                        // 입력 폼
                        VStack(alignment: .leading, spacing: 16) {
                            // 작업명
                            VStack(alignment: .leading, spacing: 6) {
                                Text("작업명")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                MockTextField(text: "CSV 데이터 정리 및 포맷 변환")
                            }

                            // 시간 입력
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("예상 시간")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Text("30분")
                                            .font(.headline.monospacedDigit())
                                            .foregroundStyle(.green)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("실제 시간")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    Text("90분")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(.red)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("낭비")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    Text("+60분")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(.red)
                                }
                            }

                            // 지연 원인
                            VStack(alignment: .leading, spacing: 6) {
                                Text("지연 원인")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                MockTextField(text: "포맷이 일관되지 않아 수작업 필요")
                            }

                            HStack(spacing: 20) {
                                // 주간 반복
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("주간 반복")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    Text("3회")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(.blue)
                                }

                                // 도구화 가능성
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("도구화 가능성")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 4) {
                                        ForEach(1...5, id: \.self) { i in
                                            Image(systemName: i <= 5 ? "star.fill" : "star")
                                                .foregroundStyle(i <= 5 ? .yellow : .gray)
                                        }
                                    }
                                }
                            }

                            // 태그
                            VStack(alignment: .leading, spacing: 6) {
                                Text("태그")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                MockTextField(text: "데이터처리, 반복작업")
                            }

                            // 저장 버튼
                            Button {} label: {
                                Text("기록 저장")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // ROI 미리보기
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("예상 ROI 점수")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .firstTextBaseline) {
                                    Text("900")
                                        .font(.title.bold().monospacedDigit())
                                        .foregroundStyle(.purple)
                                    Text("(5점 × 180분/주)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("자동화 추천")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Text("매우 높음")
                                    .font(.headline)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(24)
                }
                .frame(width: 500)
                .background(Color(.windowBackgroundColor))

                Divider()

                MockQuickStats()
                    .frame(width: 280)
            }
        }
        .frame(width: 1000, height: 600)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - 스크린샷 4: 자동화 우선순위
struct Screenshot4_AutomationPriority: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MockWindowTitleBar(title: "돌아보기")

            HStack(spacing: 0) {
                MockSidebar(selected: "대시보드")
                    .frame(width: 200)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("자동화 우선순위")
                            .font(.title.bold())

                        HStack(alignment: .top, spacing: 20) {
                            // TOP 5 병목 지점
                            VStack(alignment: .leading, spacing: 16) {
                                Label("TOP 5 병목 지점 (ROI 순)", systemImage: "exclamationmark.triangle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.orange)

                                MockTopBottleneckRow(rank: 1, name: "CSV 데이터 정리", emoji: "🔴", frequency: 3, wasted: 60, roi: 900)
                                Divider()
                                MockTopBottleneckRow(rank: 2, name: "회의록 작성", emoji: "🟠", frequency: 5, wasted: 25, roi: 500)
                                Divider()
                                MockTopBottleneckRow(rank: 3, name: "배포 프로세스", emoji: "🔴", frequency: 2, wasted: 45, roi: 450)
                                Divider()
                                MockTopBottleneckRow(rank: 4, name: "이메일 응답 정리", emoji: "🟡", frequency: 7, wasted: 20, roi: 420)
                                Divider()
                                MockTopBottleneckRow(rank: 5, name: "로그 분석", emoji: "🟠", frequency: 4, wasted: 20, roi: 320)
                            }
                            .padding(20)
                            .background(Color(.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // 도구 개발 우선순위
                            VStack(alignment: .leading, spacing: 16) {
                                Label("도구 개발 우선순위", systemImage: "hammer.fill")
                                    .font(.headline)
                                    .foregroundStyle(.purple)

                                MockPriorityCard(priority: 1, name: "CSV 데이터 정리", saving: "주 180분 절감 가능", suggestion: "높은 자동화 가능성! 스크립트나 도구 개발을 권장합니다.")

                                MockPriorityCard(priority: 2, name: "회의록 작성", saving: "주 125분 절감 가능", suggestion: "부분 자동화 가능. 템플릿이나 체크리스트로 시작해보세요.")

                                MockPriorityCard(priority: 3, name: "배포 프로세스", saving: "주 90분 절감 가능", suggestion: "높은 자동화 가능성! CI/CD 파이프라인 구축을 권장합니다.")

                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                    Text("ROI = 도구화 점수 × 주간 낭비 시간")
                                }
                                .font(.body)
                                .foregroundStyle(.secondary)
                            }
                            .padding(20)
                            .background(Color(.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(24)
                }
                .background(Color(.windowBackgroundColor))
            }
        }
        .frame(width: 1000, height: 600)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - 스크린샷 5: 전체 레이아웃
struct Screenshot5_FullLayout: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MockWindowTitleBar(title: "돌아보기")

            HStack(spacing: 0) {
                // 사이드바
                MockSidebar(selected: "전체 기록")
                    .frame(width: 200)

                Divider()

                // 기록 목록
                VStack(alignment: .leading, spacing: 0) {
                    // 검색바
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text("검색...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()

                    // 기록 목록
                    ScrollView {
                        VStack(spacing: 8) {
                            MockEntryRow(name: "CSV 데이터 정리", date: "오늘", wasted: 60, score: 5, isSelected: true)
                            MockEntryRow(name: "회의록 작성", date: "오늘", wasted: 25, score: 4, isSelected: false)
                            MockEntryRow(name: "배포 프로세스", date: "어제", wasted: 45, score: 5, isSelected: false)
                            MockEntryRow(name: "이메일 응답 정리", date: "어제", wasted: 20, score: 3, isSelected: false)
                            MockEntryRow(name: "로그 분석", date: "1/19", wasted: 20, score: 4, isSelected: false)
                            MockEntryRow(name: "테스트 데이터 생성", date: "1/19", wasted: 20, score: 5, isSelected: false)
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(width: 350)
                .background(Color(.windowBackgroundColor))

                Divider()

                // 상세 인스펙터
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("상세 정보")
                                    .font(.title2.bold())
                                Text("1월 21일 화요일")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {} label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Label("작업명", systemImage: "doc.text")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text("CSV 데이터 정리")
                                .font(.headline)
                        }

                        // 시간 정보
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("예상", systemImage: "clock")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Text("30분")
                                    .font(.headline)
                                    .foregroundStyle(.green)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Label("실제", systemImage: "clock.fill")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Text("90분")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Label("낭비", systemImage: "exclamationmark.circle")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Text("+60분")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // ROI
                        VStack(alignment: .leading, spacing: 6) {
                            Label("ROI 점수", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("900")
                                    .font(.title.bold().monospacedDigit())
                                    .foregroundStyle(.purple)
                                Text("(도구화 점수 × 주간 낭비 시간)")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // 태그
                        VStack(alignment: .leading, spacing: 6) {
                            Label("태그", systemImage: "tag")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            HStack {
                                TagPill(text: "#데이터처리")
                                TagPill(text: "#반복작업")
                            }
                        }
                    }
                    .padding()
                }
                .frame(width: 280)
                .background(Color(.windowBackgroundColor))
            }
        }
        .frame(width: 1000, height: 600)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Mock Components
struct MockWindowTitleBar: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            // 트래픽 라이트
            Circle().fill(Color.red.opacity(0.9)).frame(width: 12, height: 12)
            Circle().fill(Color.yellow.opacity(0.9)).frame(width: 12, height: 12)
            Circle().fill(Color.green.opacity(0.9)).frame(width: 12, height: 12)

            Spacer()

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            // 오른쪽 여백
            HStack(spacing: 8) {
                Circle().fill(Color.clear).frame(width: 12, height: 12)
                Circle().fill(Color.clear).frame(width: 12, height: 12)
                Circle().fill(Color.clear).frame(width: 12, height: 12)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
    }
}

struct MockSidebar: View {
    let selected: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 앱 로고
            HStack(spacing: 8) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("돌아보기")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 8)

            // 주간 낭비 시간
            HStack(spacing: 4) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.body)
                Text("이번 주 4시간 30분 낭비")
                    .font(.body)
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 12)

            // 메뉴 항목
            MockSidebarItem(icon: "plus.circle.fill", text: "오늘 기록", color: .green, isSelected: selected == "오늘 기록")
            MockSidebarItem(icon: "list.bullet.rectangle", text: "전체 기록", color: .blue, isSelected: selected == "전체 기록")
            MockSidebarItem(icon: "chart.bar.xaxis", text: "대시보드", color: .orange, isSelected: selected == "대시보드")
            MockSidebarItem(icon: "hammer.fill", text: "도구 트래커", color: .purple, isSelected: selected == "도구 트래커")
            MockSidebarItem(icon: "gearshape", text: "설정", color: .gray, isSelected: selected == "설정")

            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
}

struct MockSidebarItem: View {
    let icon: String
    let text: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? color.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct MockQuickStats: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("빠른 통계")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 12) {
                    Label("이번 주 요약", systemImage: "calendar")
                        .font(.headline)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                Text("기록 수")
                            }
                            .font(.body)
                            .foregroundStyle(.secondary)
                            Text("12")
                                .font(.title3.bold())
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text("낭비 시간")
                            }
                            .font(.body)
                            .foregroundStyle(.secondary)
                            Text("4시간 30분")
                                .font(.title3.bold())
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // TOP 3
                VStack(alignment: .leading, spacing: 12) {
                    Label("TOP 3 병목 지점", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundStyle(.orange)

                    ForEach(1...3, id: \.self) { i in
                        HStack(spacing: 12) {
                            Text("\(i)")
                                .font(.body.bold())
                                .frame(width: 20, height: 20)
                                .background(Color.orange.opacity(0.3))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(["CSV 정리", "회의록", "배포"][i-1])
                                    .font(.body.weight(.medium))
                                    .lineLimit(1)
                                Text(["🔴 도구화 5점", "🟠 도구화 4점", "🔴 도구화 5점"][i-1])
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(["+60분", "+25분", "+45분"][i-1])
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
    }
}

struct MockRetrospectiveRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(emoji)
                    .font(.title2)
                Text(title)
                    .font(.body.bold())
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70, alignment: .leading)

            Text(text)
                .font(.body)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.2))
            .clipShape(Capsule())
    }
}

struct MockTextField: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct MockPeriodButton: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text)
            .font(.body.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.controlBackgroundColor))
            .foregroundStyle(isSelected ? .white : .secondary)
            .clipShape(Capsule())
    }
}

struct MockStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2.bold().monospacedDigit())
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(title)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MockLineChart: View {
    var body: some View {
        GeometryReader { geo in
            let points: [CGFloat] = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.5]
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // 영역
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))
                    for (index, point) in points.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(points.count - 1)
                        let y = height * (1 - point)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.4), Color.red.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // 라인
                Path { path in
                    for (index, point) in points.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(points.count - 1)
                        let y = height * (1 - point)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.red, lineWidth: 2)

                // 포인트
                ForEach(0..<points.count, id: \.self) { index in
                    let x = width * CGFloat(index) / CGFloat(points.count - 1)
                    let y = height * (1 - points[index])
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

struct MockBarChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MockBarRow(tag: "데이터처리", value: 0.9, minutes: 120)
            MockBarRow(tag: "반복작업", value: 0.7, minutes: 95)
            MockBarRow(tag: "문서작업", value: 0.5, minutes: 65)
            MockBarRow(tag: "개발", value: 0.4, minutes: 55)
            MockBarRow(tag: "커뮤니케이션", value: 0.3, minutes: 40)
        }
    }
}

struct MockBarRow: View {
    let tag: String
    let value: CGFloat
    let minutes: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("#\(tag)")
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * value)
            }
            .frame(height: 16)

            Text("\(minutes)분")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

struct MockTopBottleneckRow: View {
    let rank: Int
    let name: String
    let emoji: String
    let frequency: Int
    let wasted: Int
    let roi: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.body.bold())
                .frame(width: 24, height: 24)
                .background(rank == 1 ? Color.orange : rank == 2 ? Color.gray : Color.brown)
                .foregroundStyle(.white)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(emoji)
                    Text("주 \(frequency)회")
                        .font(.body)
                        .foregroundStyle(.blue)
                    Text("+\(wasted)분/회")
                        .font(.body)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("ROI")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text("\(roi)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.purple)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MockPriorityCard: View {
    let priority: Int
    let name: String
    let saving: String
    let suggestion: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("우선순위 \(priority)")
                    .font(.body.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((priority == 1 ? Color.orange : priority == 2 ? Color.gray : Color.brown).opacity(0.2))
                    .foregroundStyle(priority == 1 ? Color.orange : priority == 2 ? Color.gray : Color.brown)
                    .clipShape(Capsule())

                Spacer()

                Text(saving)
                    .font(.body)
                    .foregroundStyle(.green)
            }

            Text(name)
                .font(.body.weight(.medium))

            Text(suggestion)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MockEntryRow: View {
    let name: String
    let date: String
    let wasted: Int
    let score: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(["🔴", "🟠", "🟡", "🔵", "⚪️"][5 - score])
                Text("\(score)")
                    .font(.body.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(date)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("+\(wasted)분")
                        .font(.body)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(isSelected ? Color.blue.opacity(0.2) : Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview("Screenshot 1 - Daily Review") {
    AppStoreScreenshotView(screenshotNumber: 1)
}

#Preview("Screenshot 2 - Dashboard") {
    AppStoreScreenshotView(screenshotNumber: 2)
}

#Preview("Screenshot 3 - Bottleneck Input") {
    AppStoreScreenshotView(screenshotNumber: 3)
}

#Preview("Screenshot 4 - Automation Priority") {
    AppStoreScreenshotView(screenshotNumber: 4)
}

#Preview("Screenshot 5 - Full Layout") {
    AppStoreScreenshotView(screenshotNumber: 5)
}

// MARK: - All Screenshots View (한 번에 보기)
struct AllScreenshotsView: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 40) {
                ForEach(1...5, id: \.self) { i in
                    VStack {
                        Text("Screenshot \(i)")
                            .font(.headline)
                            .padding(.bottom, 8)

                        AppStoreScreenshotView(screenshotNumber: i)
                            .scaleEffect(0.5)
                            .frame(width: 640, height: 400)
                    }
                }
            }
            .padding(40)
        }
    }
}

#Preview("All Screenshots") {
    AllScreenshotsView()
        .frame(width: 1400, height: 500)
}
