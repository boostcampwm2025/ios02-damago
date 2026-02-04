//
//  CardGameViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by 박현수 on 2/4/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class CardGameViewModelTests {
    private var cancellables = Set<AnyCancellable>()
    
    private class SpyAdjustCoinAmountUseCase: AdjustCoinAmountUseCase {
        var executeCalled = false
        var lastAmount: Int?
        var shouldFail = false
        
        private let continuation: AsyncStream<Void>.Continuation
        let executedStream: AsyncStream<Void>

        init() {
            var cont: AsyncStream<Void>.Continuation!
            self.executedStream = AsyncStream { cont = $0 }
            self.continuation = cont
        }

        func execute(amount: Int) async throws -> Int {
            executeCalled = true
            lastAmount = amount
            
            if shouldFail {
                continuation.yield()
                throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
            }
            
            continuation.yield()
            return amount // 혹은 적절한 더미 값
        }
    }

    struct TestInput {
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let cardTapped = PassthroughSubject<Int, Never>()
        let alertConfirmDidTap = PassthroughSubject<Void, Never>()

        var input: CardGameViewModel.Input {
            CardGameViewModel.Input(
                viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
                cardTapped: cardTapped.eraseToAnyPublisher(),
                alertConfirmDidTap: alertConfirmDidTap.eraseToAnyPublisher()
            )
        }
    }
    
    @Test("게임 시작 시 암기 모드로 진입하고 카운트다운이 시작되어야 한다")
    func testGameStartMemorizing() async throws {
        // Given
        let dummyImages = (0..<4).map { Data([UInt8($0)]) }
        let viewModel = CardGameViewModel(
            difficulty: .easy,
            images: dummyImages,
            adjustCoinAmountUseCase: SpyAdjustCoinAmountUseCase()
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        try await withTimeout(seconds: 1.0) {
            var iterator = output.values.makeAsyncIterator()
            _ = await iterator.next() // initial

            // When
            testInput.viewDidLoad.send()

            // Then
            while let state = await iterator.next() {
                if await state.gameState == .memorizing {
                    #expect(state.countdown == 3)
                    #expect(state.items.allSatisfy { $0.isFlipped == true })
                    return
                }
            }
        }
    }
    
    @Test("카드 탭 시 상태 변화 확인 (일치하는 경우)")
    func testCardMatch() async throws {
        // Given
        let dummyImages = [Data([0x01])] // 1개 이미지 -> 1쌍(2장) 생성
        let viewModel = CardGameViewModel(
            difficulty: .easy,
            images: dummyImages,
            adjustCoinAmountUseCase: SpyAdjustCoinAmountUseCase()
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        

        
        // Playing 상태가 될 때까지 대기
        try await withTimeout(seconds: 5.0) {
            var iterator = output.values.makeAsyncIterator()
            testInput.viewDidLoad.send()

            while let state = await iterator.next() {
                if await state.gameState == .playing {
                    return
                }
            }

            // When: 첫 번째 카드 탭
            testInput.cardTapped.send(0)
            _ = await iterator.next()

            // When: 두 번째 카드 탭 (Easy/1개 이미지이므로 무조건 매칭)
            testInput.cardTapped.send(1)

            // Then: 매칭 확인 및 점수 증가
            while let state = await iterator.next() {
                if await state.score == 2 {
                    #expect(state.items[0].matchingState == .match)
                    #expect(state.items[1].matchingState == .match)
                    #expect(state.gameState == .finished) // 모든 짝을 맞췄으므로 종료
                    return
                }
            }
        }
    }
    
    @Test("게임 종료 후 확인 클릭 시 코인 업데이트 및 뒤로가기 Route 발생")
    func testAdjustCoinOnFinish() async throws {
        // Given
        let spy = SpyAdjustCoinAmountUseCase()
        let dummyImages = [Data([0x01])]
        let viewModel = CardGameViewModel(
            difficulty: .easy,
            images: dummyImages,
            adjustCoinAmountUseCase: spy
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        try await withTimeout(seconds: 5.0) {
            var iterator = output.values.makeAsyncIterator()
            testInput.viewDidLoad.send()

            // Playing 대기 -> 탭 2번 -> Finished 대기
            while let state = await iterator.next() {
                if await state.gameState == .playing { break }
            }

            testInput.cardTapped.send(0)
            testInput.cardTapped.send(1)

            while let state = await iterator.next() {
                if await state.gameState == .finished { break }
            }

            // When: 알럿 확인 클릭
            testInput.alertConfirmDidTap.send()

            // Then: UseCase 호출 확인
            var spyIterator = spy.executedStream.makeAsyncIterator()
            _ = await spyIterator.next()
            #expect(spy.executeCalled == true)
            #expect(spy.lastAmount == 2)

            while let state = await iterator.next() {
                if let route = await state.route?.value, case .back = route {
                    #expect(true)
                    return
                }
            }
        }
    }
}
