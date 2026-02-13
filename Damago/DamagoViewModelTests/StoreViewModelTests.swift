//
//  StoreViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by 김재영 on 2/11/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class StoreViewModelTests {
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Mocks

    @MainActor
    class MockGlobalStore: GlobalStoreProtocol {
        var globalStateSubject = CurrentValueSubject<GlobalState, Never>(.empty)
        
        var globalState: AnyPublisher<GlobalState, Never> {
            globalStateSubject.eraseToAnyPublisher()
        }
        
        func startMonitoring(uid: String) {}
        func stopMonitoring() {}
        
        func updateState(_ state: GlobalState) {
            globalStateSubject.send(state)
        }
    }

    @MainActor
    class MockCreateDamagoUseCase: CreateDamagoUseCase {
        var executeResult: Result<DrawResult, Error>?
        var onExecute: (() -> Void)?
        
        func execute() async throws -> DrawResult {
            onExecute?()
            switch executeResult {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            case .none:
                fatalError("MockCreateDamagoUseCase의 결과가 설정되지 않았습니다.")
            }
        }
    }

    // MARK: - Test Input

    struct TestInput {
        let drawButtonDidTap = PassthroughSubject<Void, Never>()
        
        var input: StoreViewModel.Input {
            StoreViewModel.Input(
                drawButtonDidTap: drawButtonDidTap.eraseToAnyPublisher()
            )
        }
    }

    // MARK: - Tests

    @Test("초기 상태가 GlobalStore의 값을 반영해야 한다")
    func test_초기_상태_반영() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockCreateDamagoUseCase = MockCreateDamagoUseCase()
        let viewModel = StoreViewModel(
            globalStore: mockGlobalStore,
            createDamagoUseCase: mockCreateDamagoUseCase
        )
        
        let initialOwnedDamagos: [DamagoType: Int] = [.basicBlack: 1]
        let initialCoin = 500
        let state = GlobalState(
            nickname: nil,
            opponentName: nil,
            useFCM: false,
            useLiveActivity: false,
            todayPokeCount: 0,
            coupleID: nil,
            totalCoin: initialCoin,
            foodCount: nil,
            anniversaryDate: nil,
            currentQuestionID: nil,
            damagoID: nil,
            damagoName: nil,
            damagoType: nil,
            level: nil,
            currentExp: nil,
            maxExp: nil,
            isHungry: nil,
            statusMessage: nil,
            lastFedAt: nil,
            totalPlayTime: nil,
            lastActiveAt: nil,
            ownedDamagos: initialOwnedDamagos
        )
        mockGlobalStore.updateState(state)
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("상태 업데이트 확인") { confirm in
            output.filter { state in
                state.coinAmount == initialCoin && state.ownedDamagos == initialOwnedDamagos
            }
            .first()
            .sink { _ in
                confirm()
            }
            .store(in: &cancellables)
        }
    }

    @Test("코인 양에 따라 뽑기 버튼 활성화 상태와 타이틀이 변경되어야 한다", arguments: [
        (50, false, StoreViewModel.StoreStrings.notEnoughCoinLabel, "코인 부족"),
        (100, true, StoreViewModel.StoreStrings.drawButtonTitle(cost: StoreViewModel.StorePolicy.drawCost), "코인 충분")
    ])
    func test_코인_양에_따른_버튼_상태_변경(coinAmount: Int, expectedIsEnabled: Bool, expectedTitle: String, scenario: String) async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockCreateDamagoUseCase = MockCreateDamagoUseCase()
        let viewModel = StoreViewModel(
            globalStore: mockGlobalStore,
            createDamagoUseCase: mockCreateDamagoUseCase
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("버튼 상태 및 타이틀 확인 (\(scenario))") { confirm in
            output.filter { state in
                state.coinAmount == coinAmount && 
                state.isDrawButtonEnabled == expectedIsEnabled && 
                state.drawButtonTitle == expectedTitle
            }
            .first()
            .sink { _ in
                confirm()
            }
            .store(in: &cancellables)
            
            let state = GlobalState(
                nickname: nil, opponentName: nil, useFCM: false, useLiveActivity: false, todayPokeCount: 0,
                coupleID: nil, totalCoin: coinAmount, foodCount: nil, anniversaryDate: nil, currentQuestionID: nil,
                damagoID: nil, damagoName: nil, damagoType: nil, level: nil, currentExp: nil, maxExp: nil,
                isHungry: nil, statusMessage: nil, lastFedAt: nil, totalPlayTime: nil, lastActiveAt: nil, ownedDamagos: nil
            )
            mockGlobalStore.updateState(state)
        }
    }

    @Test("뽑기 버튼 클릭 시 성공적으로 다마고를 뽑아야 한다")
    func test_뽑기_성공() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockCreateDamagoUseCase = MockCreateDamagoUseCase()
        let viewModel = StoreViewModel(
            globalStore: mockGlobalStore,
            createDamagoUseCase: mockCreateDamagoUseCase
        )
        
        let expectedResult = DrawResult(damagoType: .basicBlack, isNew: true)
        mockCreateDamagoUseCase.executeResult = .success(expectedResult)
        
        let initialState = GlobalState(
            nickname: nil, opponentName: nil, useFCM: false, useLiveActivity: false, todayPokeCount: 0,
            coupleID: nil, totalCoin: 200, foodCount: nil, anniversaryDate: nil, currentQuestionID: nil,
            damagoID: nil, damagoName: nil, damagoType: nil, level: nil, currentExp: nil, maxExp: nil,
            isHungry: nil, statusMessage: nil, lastFedAt: nil, totalPlayTime: nil, lastActiveAt: nil, ownedDamagos: [:]
        )
        mockGlobalStore.updateState(initialState)
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("뽑기 결과 확인") { confirm in
            let stream = AsyncStream<Void> { continuation in
                output.compactMap { $0.drawResult }
                    .filter { $0 == expectedResult }
                    .first()
                    .sink { _ in
                        confirm()
                        continuation.yield()
                    }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            testInput.drawButtonDidTap.send(())
            await iterator.next()
        }
    }

    @Test("코인이 부족할 때 뽑기 버튼을 누르면 에러가 발생해야 한다")
    func test_코인_부족_시_에러() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockCreateDamagoUseCase = MockCreateDamagoUseCase()
        let viewModel = StoreViewModel(
            globalStore: mockGlobalStore,
            createDamagoUseCase: mockCreateDamagoUseCase
        )
        
        let state = GlobalState(
            nickname: nil, opponentName: nil, useFCM: false, useLiveActivity: false, todayPokeCount: 0,
            coupleID: nil, totalCoin: 50, foodCount: nil, anniversaryDate: nil, currentQuestionID: nil,
            damagoID: nil, damagoName: nil, damagoType: nil, level: nil, currentExp: nil, maxExp: nil,
            isHungry: nil, statusMessage: nil, lastFedAt: nil, totalPlayTime: nil, lastActiveAt: nil, ownedDamagos: nil
        )
        mockGlobalStore.updateState(state)
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("에러 발생 확인") { confirm in
            let stream = AsyncStream<Void> { continuation in
                output.compactMap { $0.error }
                    .filter { $0.value == .notEnoughCoin }
                    .first()
                    .sink { _ in
                        confirm()
                        continuation.yield()
                    }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()

            testInput.drawButtonDidTap.send(())
            await iterator.next()
        }
    }

    @Test("다마고 생성 실패 시 에러가 발생해야 한다")
    func test_생성_실패_시_에러() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockCreateDamagoUseCase = MockCreateDamagoUseCase()
        let viewModel = StoreViewModel(
            globalStore: mockGlobalStore,
            createDamagoUseCase: mockCreateDamagoUseCase
        )
        
        mockCreateDamagoUseCase.executeResult = .failure(NSError(domain: "test", code: -1))
        let state = GlobalState(
            nickname: nil, opponentName: nil, useFCM: false, useLiveActivity: false, todayPokeCount: 0,
            coupleID: nil, totalCoin: 200, foodCount: nil, anniversaryDate: nil, currentQuestionID: nil,
            damagoID: nil, damagoName: nil, damagoType: nil, level: nil, currentExp: nil, maxExp: nil,
            isHungry: nil, statusMessage: nil, lastFedAt: nil, totalPlayTime: nil, lastActiveAt: nil, ownedDamagos: nil
        )
        mockGlobalStore.updateState(state)
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("생성 실패 에러 확인") { confirm in
            let stream = AsyncStream<Void> { continuation in
                output.compactMap { $0.error }
                    .filter { $0.value == .creationFailed }
                    .first()
                    .sink { _ in
                        confirm()
                        continuation.yield()
                    }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            testInput.drawButtonDidTap.send(())
            await iterator.next()
        }
    }
}
