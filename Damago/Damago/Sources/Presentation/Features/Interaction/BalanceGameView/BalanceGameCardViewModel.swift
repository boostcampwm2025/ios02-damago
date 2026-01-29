//
//  BalanceGameCardViewModel.swift
//  Damago
//
//  Created by Eden Landelyse on 1/21/26.
//

import Combine
import Foundation
import OSLog

final class BalanceGameCardViewModel: ViewModel {
    struct Input {
        let choiceTapped: AnyPublisher<BalanceGameChoice, Never>
        let confirmResult: AnyPublisher<(BalanceGameChoice, Bool), Never>
    }

    enum MatchResult: Equatable {
        case matched
        case differed
    }

    struct State: Equatable {
        var uiModel: BalanceGameUIModel?
        var pendingConfirm: BalanceGameChoice?
        var localSelection: BalanceGameChoice?
        var showLockedAlert: Pulse<BalanceGameChoice>?
        var isLoading: Bool = false

        var myChoice: BalanceGameChoice? {
            if case .result(let result) = uiModel {
                return BalanceGameChoice(rawValue: result.myChoice)
            }
            return nil
        }

        var opponentChoice: BalanceGameChoice? {
            if case .result(let result) = uiModel, let opponentChoice = result.opponentChoice {
                return BalanceGameChoice(rawValue: opponentChoice)
            }
            return nil
        }

        var isOpponentAnswered: Bool {
            opponentChoice != nil
        }

        var matchResult: MatchResult? {
            guard let myChoice, let opponentChoice else { return nil }
            return (myChoice == opponentChoice) ? .matched : .differed
        }

        var targetDate: Date? {
            switch uiModel {
            case .input(let state): return state.nextGameAvailableAt
            case .result(let state): return state.nextGameAvailableAt
            case .none: return nil
            }
        }

        var headerStatus: String {
            if myChoice != nil && !isOpponentAnswered {
                return "상대방을 기다리는 중"
            }
            return ""
        }
    }

    private let submitAction: (BalanceGameChoice) async throws -> Void
    @Published private var state: State
    private var cancellables = Set<AnyCancellable>()

    init(
        uiModel: BalanceGameUIModel,
        uiModelPublisher: AnyPublisher<BalanceGameUIModel, Never>,
        submitAction: @escaping (BalanceGameChoice) async throws -> Void
    ) {
        self.state = State(uiModel: uiModel)
        self.submitAction = submitAction

        uiModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newModel in
                self?.state.uiModel = newModel
                self?.state.isLoading = false
                self?.state.localSelection = nil
            }
            .store(in: &cancellables)
    }

    func transform(_ input: Input) -> Output {
        input.choiceTapped
            .sink { [weak self] choice in
                guard let self else { return }
                if self.state.myChoice != nil {
                    self.state.showLockedAlert = Pulse(choice)
                } else {
                    self.state.pendingConfirm = choice
                }
            }
            .store(in: &cancellables)

        input.confirmResult
            .sink { [weak self] choice, ok in
                guard let self else { return }
                
                if ok {
                    self.handleSubmit(choice: choice)
                } else {
                    self.state.pendingConfirm = nil
                }
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    private func handleSubmit(choice: BalanceGameChoice) {
        guard !state.isLoading else { return }
        SharedLogger.interaction.info("ViewModel: 밸런스 게임 제출 프로세스 시작 (선택: \(choice.rawValue))")
        
        var newState = state
        newState.isLoading = true
        newState.localSelection = choice
        newState.pendingConfirm = nil
        state = newState
        
        Task {
            do {
                try await submitAction(choice)
            } catch {
                SharedLogger.interaction.error("밸런스 게임 제출 실패: \(error.localizedDescription)")
                await MainActor.run {
                    self.state.isLoading = false
                }
            }
        }
    }
}
