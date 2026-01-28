//
//  DailyQuestionInputViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import Combine
import Foundation
import OSLog

final class DailyQuestionInputViewModel: ViewModel {
    struct Input {
        let textDidChange: AnyPublisher<String, Never>
        let submitButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State: Equatable {
        var uiModel: DailyQuestionUIModel
        var currentText: String = ""
        var textCount: String = "0 / 200"
        var isSubmitButtonEnabled: Bool = false
        var isLoading: Bool = false
    }
    
    @Published private var state: State
    private let submitDailyQuestionAnswerUseCase: SubmitDailyQuestionAnswerUseCase
    private let manageDraftAnswerUseCase: ManageDailyQuestionDraftAnswerUseCase
    private var cancellables = Set<AnyCancellable>()
    
    private var currentQuestionID: String {
        state.uiModel.questionID
    }
    
    private var isUser1: Bool {
        state.uiModel.isUser1
    }
    
    init(
        uiModel: DailyQuestionUIModel,
        uiModelPublisher: AnyPublisher<DailyQuestionUIModel, Never>,
        submitDailyQuestionAnswerUseCase: SubmitDailyQuestionAnswerUseCase,
        manageDraftAnswerUseCase: ManageDailyQuestionDraftAnswerUseCase
    ) {
        self.submitDailyQuestionAnswerUseCase = submitDailyQuestionAnswerUseCase
        self.manageDraftAnswerUseCase = manageDraftAnswerUseCase
        
        let initialText: String
        if case .result(let resultState) = uiModel {
            initialText = resultState.myAnswer.content ?? ""
        } else {
            initialText = ""
        }
        
        self.state = State(
            uiModel: uiModel,
            currentText: initialText
        )
        
        // 저장된 임시 답변이 있으면 복원
        if case .input(let inputState) = uiModel {
            Task { @MainActor in
                if let draftAnswer = try? await manageDraftAnswerUseCase.loadDraftAnswer(questionID: inputState.questionID),
                   !draftAnswer.isEmpty {
                    self.state.currentText = draftAnswer
                    self.state.textCount = "\(draftAnswer.count) / 200"
                    self.state.isSubmitButtonEnabled = !draftAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            }
        }
        
        uiModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newModel in
                self?.state.uiModel = newModel
                if case .result = newModel {
                    self?.state.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    func transform(_ input: Input) -> Output {
        input.textDidChange
            .sink { [weak self] text in
                self?.handleTextChange(text)
            }
            .store(in: &cancellables)
        
        input.submitButtonDidTap
            .sink { [weak self] in
                self?.handleSubmit()
            }
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    private func handleTextChange(_ text: String) {
        guard case .input = state.uiModel else { return }
        
        let limitedText = String(text.prefix(200))
        state.currentText = limitedText
        state.textCount = "\(limitedText.count) / 200"
        state.isSubmitButtonEnabled = !limitedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // 답변 변경 시 자동 저장
        saveDraftAnswer()
    }
    
    private func handleSubmit() {
        guard !state.isLoading else { return }
        
        let questionID = currentQuestionID
        let answer = state.currentText
        
        state.isLoading = true
        state.isSubmitButtonEnabled = false
        
        Task {
            defer {
                self.state.isLoading = false
            }
            
            do {
                try await submitDailyQuestionAnswerUseCase.execute(
                    questionID: questionID,
                    answer: answer
                )
                
                // 답변 제출 성공 시 저장된 임시 답변 삭제
                try await manageDraftAnswerUseCase.deleteDraftAnswer(questionID: questionID)
                
            } catch {
                SharedLogger.interaction.error("답변 전송 실패: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.state.isSubmitButtonEnabled = true
                }
            }
        }
    }
    
    // MARK: - Draft Answer Management
    
    func saveDraftAnswer() {
        let questionID = currentQuestionID
        let trimmedText = state.currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task { @MainActor in
            do {
                try await manageDraftAnswerUseCase.saveDraftAnswer(
                    questionID: questionID,
                    draftAnswer: trimmedText.isEmpty ? nil : trimmedText
                )
            } catch {
                SharedLogger.interaction.error("임시 답변 저장 실패: \(error.localizedDescription)")
            }
        }
    }
}
