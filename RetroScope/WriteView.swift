import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    struct LayoutResult { var positions: [CGPoint]; var size: CGSize }
    func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        var positions: [CGPoint] = []
        var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
        let maxW = proposal.width ?? .infinity
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > maxW && x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return LayoutResult(positions: positions, size: CGSize(width: maxW, height: y + rowHeight))
    }
}

struct WriteView: View {
    @Environment(ReflectionStore.self) var store
    var onSave: (String) -> Void
    
    @State private var selectedQuestions: [ReflectionQuestion] = []
    @State private var answers: [String: String] = [:]
    @State private var selectedTags: Set<String> = []
    @State private var customTag = ""
    @State private var selectedEmotion = ""
    @State private var energyLevel = 0
    @State private var showQuestionPicker = true
    @State private var shuffledQuestions: [ReflectionQuestion] = []
    
    var hasAnyAnswer: Bool {
        answers.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var energyColor: Color {
        if energyLevel <= 3 { return .red }
        if energyLevel <= 6 { return .orange }
        return .green
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 { return "늦은 밤이네요 🌙" }
        if hour < 12 { return "좋은 아침이에요 ☀️" }
        if hour < 18 { return "오후를 보내고 계시군요 🌤" }
        return "하루가 저물어가네요 🌅"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text(greeting)
                        .font(.system(size: 28, weight: .bold))
                    Text("오늘의 회고를 시작해볼까요?")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 28)
                
                if showQuestionPicker {
                    questionPickerSection
                } else {
                    answerSection
                }
            }
            .padding(.horizontal, 40)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { shuffleQuestions() }
    }
    
    func shuffleQuestions() {
        shuffledQuestions = reflectionQuestions.shuffled()
    }
    
    // MARK: - Question Picker
    var questionPickerSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("어떤 질문에 답해볼까요?")
                    .font(.system(size: 18, weight: .semibold))
                Text("2~4개 정도 골라보세요. 모두 답하지 않아도 괜찮아요.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(shuffledQuestions) { q in
                    questionCard(q)
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    shuffleQuestions()
                } label: {
                    Label("다른 질문 보기", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    if !selectedQuestions.isEmpty {
                        withAnimation(.spring(response: 0.4)) {
                            showQuestionPicker = false
                        }
                    }
                } label: {
                    Text("이 질문들로 시작하기 →")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(selectedQuestions.isEmpty)
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }
    
    func questionCard(_ q: ReflectionQuestion) -> some View {
        let isSelected = selectedQuestions.contains(where: { $0.id == q.id })
        return Button {
            withAnimation(.spring(response: 0.25)) {
                if isSelected {
                    selectedQuestions.removeAll { $0.id == q.id }
                } else {
                    selectedQuestions.append(q)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(q.emoji).font(.system(size: 24))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 18))
                    }
                }
                Text(q.question.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Text(q.category.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.secondary.opacity(0.1)))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Answer Section
    var answerSection: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    withAnimation { showQuestionPicker = true; answers = [:] }
                } label: {
                    Label("질문 다시 고르기", systemImage: "chevron.left")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                Spacer()
            }
            
            ForEach(selectedQuestions) { q in
                questionAnswerBlock(q)
            }
            
            Divider().padding(.vertical, 8)
            
            // Tags
            VStack(alignment: .leading, spacing: 10) {
                Text("영역 태그")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 8) {
                    ForEach(defaultTags, id: \.self) { tag in
                        tagButton(tag)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 10))
                        TextField("직접 입력", text: $customTag)
                            .textFieldStyle(.plain)
                            .frame(width: 70)
                            .onSubmit {
                                if !customTag.isEmpty {
                                    selectedTags.insert(customTag)
                                    customTag = ""
                                }
                            }
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                    .foregroundStyle(.secondary)
                }
            }
            
            // Emotion
            VStack(alignment: .leading, spacing: 10) {
                Text("지금 감정")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(emotions) { em in
                        Button {
                            selectedEmotion = em.emoji
                        } label: {
                            VStack(spacing: 3) {
                                Text(em.emoji).font(.system(size: 24))
                                Text(em.label).font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedEmotion == em.emoji ? Color.orange.opacity(0.12) : .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedEmotion == em.emoji ? Color.orange.opacity(0.4) : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Energy
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("에너지 레벨")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if energyLevel > 0 {
                        Text("\(energyLevel)/10")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(energyColor)
                    }
                }
                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { level in
                        Button {
                            energyLevel = level
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(level <= energyLevel ? energyColor : Color.primary.opacity(0.08))
                                .frame(height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    Text("바닥").font(.system(size: 10)).foregroundStyle(.tertiary)
                    Spacer()
                    Text("보통").font(.system(size: 10)).foregroundStyle(.tertiary)
                    Spacer()
                    Text("충만").font(.system(size: 10)).foregroundStyle(.tertiary)
                }
            }
            
            // Save
            HStack {
                Button("초기화") { resetForm() }
                    .buttonStyle(.bordered)
                Spacer()
                Button {
                    saveReflection()
                } label: {
                    Text("회고 저장")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!hasAnyAnswer)
            }
            .padding(.bottom, 40)
        }
    }
    
    func questionAnswerBlock(_ q: ReflectionQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(q.emoji).font(.system(size: 20))
                Text(q.question)
                    .font(.system(size: 15, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { answers[q.id] ?? "" },
                    set: { answers[q.id] = $0 }
                ))
                .font(.system(size: 14))
                .frame(minHeight: 80, maxHeight: 160)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                
                if (answers[q.id] ?? "").isEmpty {
                    Text(q.placeholder)
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    func tagButton(_ tag: String) -> some View {
        let isSelected = selectedTags.contains(tag)
        return Button {
            if isSelected { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
        } label: {
            Text(tag)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? Color.orange.opacity(0.15) : Color.primary.opacity(0.05))
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? .orange : .secondary)
        }
        .buttonStyle(.plain)
    }
    
    func resetForm() {
        withAnimation {
            showQuestionPicker = true
            selectedQuestions = []
            answers = [:]
            selectedTags = []
            selectedEmotion = ""
            energyLevel = 0
            customTag = ""
        }
    }
    
    func saveReflection() {
        let questionAnswers = selectedQuestions.map { q in
            QuestionAnswer(questionId: q.id, question: q.question, answer: answers[q.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        }.filter { !$0.answer.isEmpty }
        
        guard !questionAnswers.isEmpty else { return }
        
        let entry = ReflectionEntry(
            answers: questionAnswers,
            tags: Array(selectedTags),
            emotion: selectedEmotion,
            energyLevel: energyLevel
        )
        
        store.addEntry(entry)
        onSave("✓ 회고가 저장되었습니다")
        resetForm()
    }
}
