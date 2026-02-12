# RetroScope 작업 목록

## 완료된 작업 ✅

### 2026-02-12: 빌드 에러 수정
- [x] ChartViews.swift의 타입 체크 에러 해결
  - PatternRadarView의 복잡한 body를 작은 computed properties로 분리
  - ForEach 내부의 복잡한 계산을 미리 계산된 RadarPoint 구조체로 추출
  - cos/sin 함수의 모호성 해결 (CoreGraphics 명시)
- [x] ReflectionStore.swift의 경고 수정
  - 사용하지 않는 'export' 변수 제거
- [x] 빌드 성공 확인

### 2026-02-12: 더미 데이터로 패턴 표시 기능 추가
- [x] ReflectionStore에 loadDummyData() 함수 추가
  - JSON 기반 8개의 더미 회고 데이터 생성
  - 반복되는 태그: "업무", "시간관리", "관계"
  - 반복되는 감정: "😤", "😔", "😰"
  - 낮은 에너지 레벨 (2-4)
  - "never_again", "energy_drain" 질문에 답변 포함
  - "회의", "시간관리" 키워드 반복
- [x] PatternListView의 empty state에 "더미 데이터 로드" 버튼 추가
- [x] 빌드 성공 확인

### 2026-02-12: 고급 인과관계 추론 시스템 구축
- [x] Models.swift - DiscoveredPattern 구조체 확장 (Lines 143-159)
  - possibleCauses: 이 패턴의 가능한 원인들
  - symptoms: 이 패턴으로 인한 증상들
  - relatedPatternIds: 연관된 패턴 ID들
  - correlationScore: 연관성 점수 (0.0-1.0)
- [x] PatternEngine.swift - 인과관계 분석 로직 구현 (Lines 307-429)
  - analyzeCausalRelationships(): 메인 분석 함수
  - calculateCorrelations(): Jaccard similarity로 패턴 간 상관도 계산 (0.3 이상만)
  - classifyCausesAndSymptoms(): 타입별 우선순위로 원인/증상 분류
    - 원인 우선순위: keyword(4) > recurringTheme(3) > questionPattern(2) > timePattern(1)
    - 증상 우선순위: emotion(4) > energy(3) > questionPattern(2)
  - 날짜 기반 동시 발생 분석 (2일 이상 겹칠 때)
- [x] PatternView.swift - UI에 원인/증상 표시 (Lines 204-275)
  - 🔍 "가능한 원인" 섹션 (빨간색 테두리)
  - ⚠️ "관찰된 증상" 섹션 (주황색 테두리)
- [x] 빌드 성공 확인
- [x] 더미 데이터 UI 버튼 제거 (프로덕션 준비)

## 진행중인 작업 🚧

(없음)

## 예정된 작업 📋

(없음)
