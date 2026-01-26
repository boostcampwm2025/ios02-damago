//
//  BalanceGameCardViewModel.swift
//  Damago
//
//  Created by Eden Landelyse on 1/21/26.
//

import Combine
import Foundation

final class BalanceGameCardViewModel: ViewModel {
    struct Input {
        let choiceTapped: AnyPublisher<BalanceGameChoice, Never>
        let confirmResult: AnyPublisher<(BalanceGameChoice, Bool), Never>
        let reset: AnyPublisher<Void, Never>
    }

    enum MatchResult: Equatable {
        case matched
        case differed
    }

    struct State: Equatable {
        var selectedChoice: BalanceGameChoice?
        var pendingConfirm: BalanceGameChoice?
        var showLockedAlert: Pulse<BalanceGameChoice>?

        var isOpponentAnswered: Bool = false
        var opponentChoice: BalanceGameChoice?
        var matchResult: MatchResult?

        var targetDate: Date? = nil // 초기값 nil

        var headerStatus: String? {
            // 내가 선택은 했지만 아직 결과가 나오지 않은 경우 (상대방 대기 중)
            if selectedChoice != nil && !isOpponentAnswered {
                return "상대방의 선택을 기다리고 있어요."
            }
            return nil
        }
    }

    private enum Action {
        case tapped(BalanceGameChoice)
        case confirmed(choice: BalanceGameChoice, ok: Bool)
        case reset
    }

    func transform(_ input: Input) -> Output {
        let tapAction = input.choiceTapped.map { Action.tapped($0) }
        let confirmAction = input.confirmResult.map { choice, ok in
            Action.confirmed(choice: choice, ok: ok)
        }
        let resetAction = input.reset.map { Action.reset }

        let actions = Publishers.Merge3(tapAction, confirmAction, resetAction)

        return actions
            .scan(
                State()
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
                    nextState.selectedChoice = choice

                    // 결과가 나오는 시점, opponentChoice 수정으로 테스트
                    let opponentChoice = BalanceGameChoice.right
                    nextState.isOpponentAnswered = false
                    nextState.opponentChoice = nil
                    nextState.matchResult = (choice == opponentChoice) ? .matched : .differed

                    // 결과가 나왔으므로 다음 게임까지의 타겟 데이트 설정
                    nextState.targetDate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))

                case .reset:
                    nextState = State()
                }
                return nextState
            }
            .mapForUI { $0 }
    }
}
