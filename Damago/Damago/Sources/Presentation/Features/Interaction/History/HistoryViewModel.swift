//
//  HistoryViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import Combine
import Foundation

final class HistoryViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let segmentDidChange: AnyPublisher<Int, Never>
    }
    
    struct State {
        var selectedSegmentIndex: Int = 0
        var dailyQuestions: [DailyQuestionHistory] = []
        var balanceGames: [BalanceGameHistory] = []
        var isLoading: Bool = false
        var route: Pulse<Route>?

        var matchRate: Int {
            guard !balanceGames.isEmpty else { return 0 }
            let matchCount = balanceGames.filter { $0.isMatch }.count
            return Int((Double(matchCount) / Double(balanceGames.count)) * 100)
        }
    }

    enum Route {
        case alert(title: String, message: String)
    }

    @Published private(set) var state = State()
    private var cancellables = Set<AnyCancellable>()
    private let fetchDailyQuestionsHistoryUseCase: FetchDailyQuestionsHistoryUseCase
    private let fetchBalanceGamesHistoryUseCase: FetchBalanceGamesHistoryUseCase

    init(
        fetchDailyQuestionsHistoryUseCase: FetchDailyQuestionsHistoryUseCase,
        fetchBalanceGamesHistoryUseCase: FetchBalanceGamesHistoryUseCase
    ) {
        self.fetchDailyQuestionsHistoryUseCase = fetchDailyQuestionsHistoryUseCase
        self.fetchBalanceGamesHistoryUseCase = fetchBalanceGamesHistoryUseCase
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .sink { [weak self] in
                self?.fetchData()
            }
            .store(in: &cancellables)
            
        input.segmentDidChange
            .removeDuplicates()
            .sink { [weak self] index in
                guard let self = self else { return }
                self.state.selectedSegmentIndex = index
                self.fetchData()
            }
            .store(in: &cancellables)
            
        return $state.eraseToAnyPublisher()
    }
    
    private func fetchData() {
        state.isLoading = true
        
        let isDailyQuestion = state.selectedSegmentIndex == 0
        
        Task {
            do {
                if isDailyQuestion {
                    let items = try await fetchDailyQuestionsHistoryUseCase.execute(limit: 20)
                    self.state.dailyQuestions = items
                } else {
                    let items = try await fetchBalanceGamesHistoryUseCase.execute(limit: 20)
                    self.state.balanceGames = items
                }
            } catch {
                self.state.route = .init(.alert(title: "에러", message: error.localizedDescription))
            }
            self.state.isLoading = false
        }
    }
}
