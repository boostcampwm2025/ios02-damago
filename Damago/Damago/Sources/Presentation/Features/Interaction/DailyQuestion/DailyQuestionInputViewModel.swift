//
//  DailyQuestionInputViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import Combine
import Foundation

final class DailyQuestionInputViewModel: ViewModel {
    let answerCompleted = PassthroughSubject<String, Never>()
    
    struct Input {
        let textDidChange: AnyPublisher<String, Never>
        let submitButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State: Equatable {
        var uiModel: DailyQuestionUIModel
        var currentText: String = ""
        var textCount: String = "0 / 200"
        var isSubmitButtonEnabled: Bool = false
    }
    
    @Published private var state: State
    private var cancellables = Set<AnyCancellable>()
    
    init(uiModel: DailyQuestionUIModel) {
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
        
        // TODO: 서버 전송 로직 구현 (questionID 사용)
        // let questionID = inputState.questionID
        
        let answer = state.currentText
        
        // 로컬 상태 즉시 업데이트 (낙관적 업데이트)
        state.uiModel = Self.makeResultModel(
            questionID: inputState.questionID,
            questionContent: inputState.questionContent,
            myAnswer: answer,
            opponentAnswer: nil
        )
        answerCompleted.send(answer)
    }
    
    private static func makeResultModel(
        questionID: String,
        questionContent: String,
        myAnswer: String,
        opponentAnswer: String?
    ) -> DailyQuestionUIModel {
        let myCard = AnswerCardUIModel(
            type: .unlocked,
            title: "나의 답변",
            content: myAnswer,
            placeholderText: nil,
            iconName: nil
        )
        
        let opponentCard: AnswerCardUIModel
        if let opponentAnswer {
            opponentCard = AnswerCardUIModel(
                type: .unlocked,
                title: "상대의 답변",
                content: opponentAnswer,
                placeholderText: nil,
                iconName: nil
            )
        } else {
            opponentCard = AnswerCardUIModel(
                type: .locked,
                title: "상대의 답변",
                content: nil,
                placeholderText: "상대방이 아직 고민 중이에요...",
                iconName: "hourglass"
            )
        }
        
        return .result(.init(
            questionID: questionID,
            questionContent: questionContent,
            myAnswer: myCard,
            opponentAnswer: opponentCard
        ))
    }
}
