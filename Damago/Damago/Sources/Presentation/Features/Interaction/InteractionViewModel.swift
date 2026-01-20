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
        var dailyQuestionUIModel: DailyQuestionUIModel?
        var route: Pulse<Route>?
    }
    
    enum Route {
        case questionInput(uiModel: DailyQuestionUIModel)
        case history
    }
    
    private let fetchDailyQuestionUseCase: FetchDailyQuestionUseCase
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    init(fetchDailyQuestionUseCase: FetchDailyQuestionUseCase) {
        self.fetchDailyQuestionUseCase = fetchDailyQuestionUseCase
    }
    
    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.fetchDailyQuestionData()
            }
            .store(in: &cancellables)
        
        input.questionSubmitButtonDidTap
            .sink { [weak self] in
                guard let self, let uiModel = self.state.dailyQuestionUIModel else { return }
                self.state.route = Pulse(.questionInput(uiModel: uiModel))
            }
            .store(in: &cancellables)
        
        input.answerDidSubmitted
            .sink { [weak self] answerText in
                // TODO: Update local state if needed or re-fetch
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
        Task {
            do {
                let uiModel = try await fetchDailyQuestionUseCase.execute()
                self.state.dailyQuestionUIModel = uiModel
            } catch {
                // TODO: Handle Error
                print("오늘의 질문 가져오기 실패: \(error)")
            }
        }
    }
}
