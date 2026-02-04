//
//  CardGameViewModel.swift
//  Damago
//
//  Created by 박현수 on 2026/01/28.
//

import Combine
import Foundation

final class CardGameViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let cardTapped: AnyPublisher<Int, Never>
        let alertConfirmDidTap: AnyPublisher<Void, Never>
    }

    struct State {
        var items: [CardItem]
        var gameState: CardGameState = .ready
        var remainingMilliseconds = 20000
        let maximumMilliseconds = 20000
        var score: Int = 0
        var selectedIndices = [Int]()
        var countdown: Int?
        let difficulty: CardGameDifficulty
        var route: Pulse<Route>?
    }

    enum Route {
        case alert(title: String, message: String)
        case back
    }

    @Published private var state: State
    private var cancellables = Set<AnyCancellable>()

    private var timer: AnyCancellable?

    private let adjustCoinAmountUseCase: AdjustCoinAmountUseCase

    init(difficulty: CardGameDifficulty, images: [Data], adjustCoinAmountUseCase: AdjustCoinAmountUseCase) {
        let items = Self.createItems(difficulty: difficulty, images: images)
        self.state = State(items: items, difficulty: difficulty)
        self.adjustCoinAmountUseCase = adjustCoinAmountUseCase
    }

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.startMemorization()
            }
            .store(in: &cancellables)

        input.cardTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.handleCardTap(at: index)
            }
            .store(in: &cancellables)

        input.alertConfirmDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.adjustCoinAmount()
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    private func startMemorization() {
        state.gameState = .memorizing
        state.countdown = 3
        
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .prefix(3)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let currentCount = self.state.countdown {
                    let nextCount = currentCount - 1
                    if nextCount > 0 {
                        self.state.countdown = nextCount
                    } else {
                        self.state.countdown = nil
                        self.startGame()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func startGame() {
        state.items = state.items.map {
            var card = $0
            card.isFlipped = false
            return card
        }
        state.gameState = .playing
        startTimer()
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.state.remainingMilliseconds -= 100

                if self.state.remainingMilliseconds <= 0 {
                    self.endGame(reason: .timeUp)
                }
            }
    }

    private func handleCardTap(at index: Int) {
        guard state.gameState == .playing,
              index < state.items.count,
              !state.items[index].isFlipped,
              !state.items[index].isMatched,
              state.items[index].matchingState == .none,
              state.selectedIndices.count < 2 else { return }

        state.items[index].isFlipped = true
        state.selectedIndices.append(index)

        if state.selectedIndices.count == 2 { checkMatch() }
    }

    private func checkMatch() {
        let firstIndex = state.selectedIndices[0]
        let secondIndex = state.selectedIndices[1]

        let item1 = state.items[firstIndex]
        let item2 = state.items[secondIndex]

        let isMatch = item1.image == item2.image

        if isMatch {
            state.items[firstIndex].isMatched = true
            state.items[firstIndex].matchingState = .match
            state.items[secondIndex].isMatched = true
            state.items[secondIndex].matchingState = .match
            state.score += 2
        } else {
            state.items[firstIndex].matchingState = .mismatch
            state.items[secondIndex].matchingState = .mismatch
        }

        state.selectedIndices.removeAll()
        checkGameStatus()
    }

    private func checkGameStatus() {
        let allMatched = state.items.allSatisfy { $0.matchingState == .match }
        if allMatched {
            endGame(reason: .allCleared)
            return
        }

        let unselectedCards = state.items.filter { $0.matchingState == .none }
        if unselectedCards.isEmpty {
            endGame(reason: .allSelected)
            return
        }

        let remainingCards = state.items.filter { $0.matchingState == .none }
        let hasPlayablePair = remainingCards.contains { card in
            remainingCards.contains { otherCard in
                card.id != otherCard.id && card.image == otherCard.image
            }
        }
        if !hasPlayablePair {
            endGame(reason: .noPairsLeft)
        }
    }

    private func endGame(reason: GameEndReason) {
        timer?.cancel()
        timer = nil
        state.gameState = .finished

        let message = "\(reason.rawValue)\n획득 코인: \(state.score)"
        state.route = .init(.alert(title: "게임 종료", message: message))
    }

    private func adjustCoinAmount() {
        Task {
            do {
                try await adjustCoinAmountUseCase.execute(amount: state.score)
                state.route = .init(.back)
            } catch {
                state.route = .init(.alert(title: "에러", message: error.userFriendlyMessage))
            }
        }
    }

    private static func createItems(difficulty: CardGameDifficulty, images: [Data]) -> [CardItem] {
        let pairCount = difficulty.cardCount / 2

        return (0..<pairCount)
            .map { images[$0 % images.count] } // 인덱스 에러 방지
            .flatMap { image in
                [
                    CardItem(id: UUID(), image: image, isFlipped: true, isMatched: false),
                    CardItem(id: UUID(), image: image, isFlipped: true, isMatched: false)
                ]
            }
            .shuffled()
    }
}

extension CardGameViewModel {
    private enum GameEndReason: String {
        case timeUp = "시간이 종료되었습니다!"
        case allCleared = "모든 짝을 찾았습니다!"
        case allSelected = "모든 카드를 선택했습니다!"
        case noPairsLeft = "남아있는 짝이 없습니다!"
    }

    enum CardGameState {
        case ready
        case memorizing
        case playing
        case finished
    }
}
