//
//  DailyQuestionInputViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import Combine
import Foundation

final class DailyQuestionInputViewModel: ViewModel {
    let question: String
    let answerCompleted = PassthroughSubject<String, Never>()
    
    private var mySavedAnswer: String?
    private let opponentAnswer: String?
    
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
    
    init(question: String, myAnswer: String? = nil, opponentAnswer: String? = nil) {
        self.question = question
        self.mySavedAnswer = myAnswer
        self.opponentAnswer = opponentAnswer
        
        let initialUIModel: DailyQuestionUIModel
        if let myAnswer {
            initialUIModel = Self.makeResultModel(myAnswer: myAnswer, opponentAnswer: opponentAnswer)
        } else {
            initialUIModel = .input(.init(placeholder: "여기에 답변을 입력하세요.", buttonTitle: "답변 제출"))
        }
        
        self.state = State(
            uiModel: initialUIModel,
            currentText: myAnswer ?? ""
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
        // TODO: 서버 전송 로직
        // 성공 시 상태 변경
        let answer = state.currentText
        self.mySavedAnswer = answer
        
        state.uiModel = Self.makeResultModel(myAnswer: answer, opponentAnswer: opponentAnswer)
        answerCompleted.send(answer)
    }
    
    private static func makeResultModel(myAnswer: String, opponentAnswer: String?) -> DailyQuestionUIModel {
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
        
        return .result(.init(myAnswer: myCard, opponentAnswer: opponentCard))
    }
}
