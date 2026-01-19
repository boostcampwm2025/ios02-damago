//
//  InteractionViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/15/26.
//

import Combine
import Foundation

final class InteractionViewModel: ViewModel {
    let title = "커플 활동"
    let subtitle = "더 가까워지기 위한 일상 활동"
    
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let questionSubmitButtonDidTap: AnyPublisher<Void, Never>
        let answerDidSubmitted: AnyPublisher<String, Never>
        let historyButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State {
        var dailyQuestion: String = ""
        var myAnswer: String?
        var opponentAnswer: String?
        var route: Pulse<Route>?
    }
    
    enum Route {
        case questionInput(question: String, myAnswer: String?, opponentAnswer: String?)
        case history
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    init() { }
    
    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.fetchDailyQuestionData()
            }
            .store(in: &cancellables)
        
        input.questionSubmitButtonDidTap
            .sink { [weak self] in
                guard let self else { return }
                self.state.route = Pulse(.questionInput(
                        question: self.state.dailyQuestion,
                        myAnswer: self.state.myAnswer,
                        opponentAnswer: self.state.opponentAnswer
                    )
                )
            }
            .store(in: &cancellables)
        
        input.answerDidSubmitted
            .sink { [weak self] answerText in
                self?.state.myAnswer = answerText
            }
            .store(in: &cancellables)
        
        input.historyButtonDidTap
            .sink { [weak self] in
                self?.state.route = Pulse(.history)
            }
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    private func fetchDailyQuestionData() {
        // TODO: 서버로부터 갱신
        state.dailyQuestion = "\"우리의 첫 여행에서 가장 좋았던 추억은 무엇인가요?\""
        state.myAnswer = nil
        state.opponentAnswer = nil
    }
}
