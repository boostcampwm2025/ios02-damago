//
//  DailyQuestionInputViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import Combine
import Foundation

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
    private var cancellables = Set<AnyCancellable>()
    
    init(
        uiModel: DailyQuestionUIModel,
        uiModelPublisher: AnyPublisher<DailyQuestionUIModel, Never>,
        submitDailyQuestionAnswerUseCase: SubmitDailyQuestionAnswerUseCase
    ) {
        let initialText: String
        if case .result(let resultState) = uiModel {
            initialText = resultState.myAnswer.content ?? ""
        } else {
            initialText = ""
        }
        
        self.submitDailyQuestionAnswerUseCase = submitDailyQuestionAnswerUseCase
        self.state = State(
            uiModel: uiModel,
            currentText: initialText
        )
        
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
    }
    
    private func handleSubmit() {
        guard case .input(let inputState) = state.uiModel else { return }
        guard !state.isLoading else { return }
        
        let questionID = inputState.questionID
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
                
            } catch {
                // TODO: Handle Error
                print("답변 전송 실패: \(error)")
                
                await MainActor.run {
                    self.state.isSubmitButtonEnabled = true
                }
            }
        }
    }
}
