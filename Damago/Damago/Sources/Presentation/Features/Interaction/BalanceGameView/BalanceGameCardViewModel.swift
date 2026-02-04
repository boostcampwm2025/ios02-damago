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
        var cachedTargetDate: Date? // 날짜 유실 방지용 캐시

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
            let lastAnsweredAt: Date?
            switch uiModel {
            case .input(let state): lastAnsweredAt = state.lastAnsweredAt
            case .result(let state): lastAnsweredAt = state.lastAnsweredAt
            case .none: lastAnsweredAt = nil
            }
            
            // 양쪽 모두 답변 완료된 상태에서만 12시간 타이머 계산
            if let lastAnsweredAt, isOpponentAnswered {
                let target = lastAnsweredAt.addingTimeInterval(12 * 3600)
                return target
            }
            
            // 만약 새로 들어온 값이 nil인데 캐시된 값이 있다면 캐시 사용 (단, 상대방 답변이 있을 때만)
            if isOpponentAnswered, let cached = cachedTargetDate {
                return cached
            }
            
            return nil
        }

        var headerStatus: String {
            if myChoice != nil && isOpponentAnswered {
                return "다음 게임"
            }
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
        // 1. 모든 저장 프로퍼티를 먼저 초기화 (self 사용 전 필수)
        self.submitAction = submitAction
        var initialState = State(uiModel: uiModel)
        
        // 2. 초기 데이터에서 캐시된 날짜 설정
        let lastAnsweredAt: Date?
        switch uiModel {
        case .input(let inputState): lastAnsweredAt = inputState.lastAnsweredAt
        case .result(let resultState): lastAnsweredAt = resultState.lastAnsweredAt
        }
        
        // 상대방 답변이 있는 결과 상태라면 캐시 저장
        if let date = lastAnsweredAt, 
           case .result(let res) = uiModel, res.opponentChoice != nil {
            initialState.cachedTargetDate = date.addingTimeInterval(12 * 3600)
        }
        
        self.state = initialState

        // 3. 데이터 관찰 시작
        uiModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newModel in
                guard let self = self else { return }
                
                // 로컬 상태 업데이트
                self.state.uiModel = newModel
                self.state.isLoading = false
                self.state.localSelection = nil
                
                // 새로운 모델에 유효한 날짜가 포함되어 있다면 캐시 업데이트
                let newDate: Date?
                switch newModel {
                case .input(let inputState): newDate = inputState.lastAnsweredAt
                case .result(let resultState): newDate = resultState.lastAnsweredAt
                }
                
                if let date = newDate, self.state.isOpponentAnswered {
                    self.state.cachedTargetDate = date.addingTimeInterval(12 * 3600)
                }
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
