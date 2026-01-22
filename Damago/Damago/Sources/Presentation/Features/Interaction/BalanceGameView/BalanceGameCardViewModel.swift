//
//  BalanceGameCardViewModel.swift
//  Damago
//
//  Created by Eden Landelyse on 1/21/26.
//

import Combine

final class BalanceGameCardViewModel: ViewModel {
    struct Input {
        let choiceTapped: AnyPublisher<BalanceGameChoice, Never>
        let confirmResult: AnyPublisher<(BalanceGameChoice, Bool), Never>
    }

    struct State: Equatable {
        var selectedChoice: BalanceGameChoice?
        var pendingConfirm: BalanceGameChoice?
        var showLockedAlert: Pulse<BalanceGameChoice>?
    }

    private enum Action {
        case tapped(BalanceGameChoice)
        case confirmed(choice: BalanceGameChoice, ok: Bool)
    }

    func transform(_ input: Input) -> Output {
        let tapAction = input.choiceTapped.map { Action.tapped($0) }
        let confirmAction = input.confirmResult.map { choice, ok in
            Action.confirmed(choice: choice, ok: ok)
        }
        let actions = Publishers.Merge(tapAction, confirmAction)

        return actions
            .scan(
                State(selectedChoice: nil, pendingConfirm: nil, showLockedAlert: nil)
            ) { previousState, action in
                var nextState = previousState
                nextState.showLockedAlert = nil

                switch action {
                case .tapped(let choice):
                    if let selectedChoice = previousState.selectedChoice {
                        nextState.showLockedAlert = Pulse(selectedChoice)
                    } else {
                        nextState.pendingConfirm = choice
                    }

                case .confirmed(let choice, let ok):
                    nextState.pendingConfirm = nil
                    guard ok else { break }
                    if nextState.selectedChoice == choice {
                        nextState.selectedChoice = nil
                    }
                    else {
                        nextState.selectedChoice = choice
                    }
                }
                return nextState
            }
            .mapForUI { $0 }
    }
}
