//
//  HomeViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by Gemini on 2/4/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class HomeViewModelTests {
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Mocks

    @MainActor
    class MockGlobalStore: GlobalStoreProtocol {
        var globalStateSubject = CurrentValueSubject<GlobalState, Never>(.empty)
        
        var globalState: AnyPublisher<GlobalState, Never> {
            globalStateSubject.eraseToAnyPublisher()
        }
        
        var isMonitoring = false
        
        func startMonitoring(uid: String) {
            isMonitoring = true
        }
        
        func stopMonitoring() {
            isMonitoring = false
        }
        
        func updateState(_ state: GlobalState) {
            globalStateSubject.send(state)
        }
    }

    @MainActor
    class mockFetchUserInfoUseCase: FetchUserInfoUseCase {
        var executeResult: Result<UserInfo, Error>?
        var onExecute: (() -> Void)?
        
        func execute() async throws -> UserInfo {
            onExecute?()
            switch executeResult {
            case .success(let userInfo):
                return userInfo
            case .failure(let error):
                throw error
            case .none:
                fatalError("mockFetchUserInfoUseCase의 결과가 설정되지 않았습니다.")
            }
        }
    }

    @MainActor
    class mockFeedDamagoUseCase: FeedDamagoUseCase {
        var executeCalled = false
        var executeResult: Result<Void, Error> = .success(())
        var onExecute: (() -> Void)?
        
        func execute(damagoID: String) async throws {
            executeCalled = true
            onExecute?()
            switch executeResult {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    @MainActor
    class mockPokeDamagoUseCase: PokeDamagoUseCase {
        var executeCalled = false
        var lastMessage: String?
        var executeResult: Result<Bool, Error> = .success(true)
        var onExecute: (() -> Void)?
        
        func execute(message: String) async throws -> Bool {
            executeCalled = true
            lastMessage = message
            onExecute?()
            switch executeResult {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        }
    }

    @MainActor
    class mockUpdateUserUseCase: UpdateUserUseCase {
        var executeCalled = false
        var lastDamagoName: String?
        var executeResult: Result<Void, Error> = .success(())
        var onExecute: (() -> Void)?
        
        func execute(
            nickname: String?,
            anniversaryDate: Date?,
            useFCM: Bool?,
            useLiveActivity: Bool?,
            damagoName: String?,
            damagoType: DamagoType?
        ) async throws {
            executeCalled = true
            self.lastDamagoName = damagoName
            onExecute?()
            switch executeResult {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    // MARK: - Test Input

    struct TestInput {
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let feedButtonDidTap = PassthroughSubject<Void, Never>()
        let pokeMessageSelected = PassthroughSubject<String, Never>()
        let damagoNameChangeSubmitted = PassthroughSubject<String, Never>()
        
        var input: HomeViewModel.Input {
            HomeViewModel.Input(
                viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
                feedButtonDidTap: feedButtonDidTap.eraseToAnyPublisher(),
                pokeMessageSelected: pokeMessageSelected.eraseToAnyPublisher(),
                damagoNameChangeSubmitted: damagoNameChangeSubmitted.eraseToAnyPublisher()
            )
        }
    }

    // MARK: - Tests

    @Test("ViewDidLoad 호출 시 유저 정보를 가져오고 상태를 업데이트해야 한다")
    func test_viewDidLoad_시_유저_정보를_가져오고_상태를_업데이트한다() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockFetchUserInfoUseCase = mockFetchUserInfoUseCase()
        let mockFeedDamagoUseCase = mockFeedDamagoUseCase()
        let mockPokeDamagoUseCase = mockPokeDamagoUseCase()
        let mockUpdateUserUseCase = mockUpdateUserUseCase()
        
        let expectedUserInfo = UserInfo(
            uid: "testUID",
            damagoID: "damago123",
            coupleID: nil,
            partnerUID: nil,
            nickname: "Tester",
            damagoStatus: DamagoStatus(
                damagoName: "다마고치",
                damagoType: .basicBlack,
                level: 5,
                currentExp: 50,
                maxExp: 100,
                isHungry: true,
                statusMessage: "배고파요",
                lastFedAt: Date(),
                totalPlayTime: 100,
                lastActiveAt: Date()
            ),
            totalCoin: 1000,
            lastFedAt: Date()
        )
        mockFetchUserInfoUseCase.executeResult = .success(expectedUserInfo)
        
        let viewModel = HomeViewModel(
            globalStore: mockGlobalStore,
            fetchUserInfoUseCase: mockFetchUserInfoUseCase,
            feedDamagoUseCase: mockFeedDamagoUseCase,
            pokeDamagoUseCase: mockPokeDamagoUseCase,
            updateUserUseCase: mockUpdateUserUseCase
        )
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("상태가 유저 정보로 업데이트되어야 함") { confirm in
            let stream = AsyncStream<Void> { continuation in
                mockFetchUserInfoUseCase.onExecute = { continuation.yield() }
            }
            var iterator = stream.makeAsyncIterator()

            output.map { $0.damagoName }
                .removeDuplicates()
                .filter { $0 == "다마고치" }
                .sink { _ in confirm() }
                .store(in: &cancellables)
            
            testInput.viewDidLoad.send(())
            await iterator.next()
        }
    }

    @Test("먹이 주기 버튼 클릭 시 UseCase가 실행되어야 한다")
    func test_먹이주기_버튼_탭_시_UseCase_실행() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockFetchUserInfoUseCase = mockFetchUserInfoUseCase()
        let mockFeedDamagoUseCase = mockFeedDamagoUseCase()
        let mockPokeDamagoUseCase = mockPokeDamagoUseCase()
        let mockUpdateUserUseCase = mockUpdateUserUseCase()
        
        mockFetchUserInfoUseCase.executeResult = .success(UserInfo(
            uid: "uid",
            damagoID: "validDamagoID",
            coupleID: nil,
            partnerUID: nil,
            nickname: nil,
            damagoStatus: nil,
            totalCoin: 0,
            lastFedAt: nil
        ))
        
        let viewModel = HomeViewModel(
            globalStore: mockGlobalStore,
            fetchUserInfoUseCase: mockFetchUserInfoUseCase,
            feedDamagoUseCase: mockFeedDamagoUseCase,
            pokeDamagoUseCase: mockPokeDamagoUseCase,
            updateUserUseCase: mockUpdateUserUseCase
        )
        
        let testInput = TestInput()
        _ = viewModel.transform(testInput.input)
        
        // Step 1: ViewDidLoad 완료 대기
        await confirmation("유저 정보 로드 완료") { confirm in
            let stream = AsyncStream<Void> { continuation in
                mockFetchUserInfoUseCase.onExecute = {
                    confirm()
                    continuation.yield()
                }
            }
            var iterator = stream.makeAsyncIterator()
            testInput.viewDidLoad.send(())
            await iterator.next()
        }
        
        // Step 2: Feed 실행 및 검증
        await confirmation("먹이 주기 UseCase 실행 완료") { confirm in
            let stream = AsyncStream<Void> { continuation in
                mockFeedDamagoUseCase.onExecute = {
                    confirm()
                    continuation.yield()
                }
            }
            var iterator = stream.makeAsyncIterator()
            testInput.feedButtonDidTap.send(())
            await iterator.next()
        }
        
        #expect(mockFeedDamagoUseCase.executeCalled)
    }

    @Test("콕 찌르기 메시지 선택 시 UseCase가 실행되어야 한다")
    func test_콕찌르기_메시지_선택_시_UseCase_실행() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockFetchUserInfoUseCase = mockFetchUserInfoUseCase()
        let mockFeedDamagoUseCase = mockFeedDamagoUseCase()
        let mockPokeDamagoUseCase = mockPokeDamagoUseCase()
        let mockUpdateUserUseCase = mockUpdateUserUseCase()
        
        let viewModel = HomeViewModel(
            globalStore: mockGlobalStore,
            fetchUserInfoUseCase: mockFetchUserInfoUseCase,
            feedDamagoUseCase: mockFeedDamagoUseCase,
            pokeDamagoUseCase: mockPokeDamagoUseCase,
            updateUserUseCase: mockUpdateUserUseCase
        )
        
        let testInput = TestInput()
        _ = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("콕 찌르기 UseCase 실행 완료") { confirm in
            let stream = AsyncStream<Void> { continuation in
                mockPokeDamagoUseCase.onExecute = {
                    confirm()
                    continuation.yield()
                }
            }
            var iterator = stream.makeAsyncIterator()
            
            testInput.pokeMessageSelected.send("안녕")
            await iterator.next()
        }
        
        #expect(mockPokeDamagoUseCase.executeCalled)
        #expect(mockPokeDamagoUseCase.lastMessage == "안녕")
    }
    
    @Test("이름 변경 제출 시 UseCase가 실행되고 상태가 성공으로 변경되어야 한다")
    func test_이름변경_제출_시_UseCase_실행_및_상태변경() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockFetchUserInfoUseCase = mockFetchUserInfoUseCase()
        let mockFeedDamagoUseCase = mockFeedDamagoUseCase()
        let mockPokeDamagoUseCase = mockPokeDamagoUseCase()
        let mockUpdateUserUseCase = mockUpdateUserUseCase()
        
        let viewModel = HomeViewModel(
            globalStore: mockGlobalStore,
            fetchUserInfoUseCase: mockFetchUserInfoUseCase,
            feedDamagoUseCase: mockFeedDamagoUseCase,
            pokeDamagoUseCase: mockPokeDamagoUseCase,
            updateUserUseCase: mockUpdateUserUseCase
        )
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("이름 변경 UseCase 실행 및 성공 경로 확인", expectedCount: 2) { confirm in
            var isUseCaseExecuted = false
            var isRouteChanged = false
            
            let stream = AsyncStream<Void> { continuation in
                // UpdateUserUseCase 실행
                mockUpdateUserUseCase.onExecute = {
                    if !isUseCaseExecuted {
                        isUseCaseExecuted = true
                        confirm()
                        continuation.yield()
                    }
                }
                
                // Route 변경
                output.compactMap { $0.route }
                    .compactMap { $0.value }
                    .filter { $0 == .nameChangeSuccess }
                    .sink { _ in
                        if !isRouteChanged {
                            isRouteChanged = true
                            confirm()
                            continuation.yield()
                        }
                    }
                    .store(in: &cancellables)
            }
            
            var iterator = stream.makeAsyncIterator()
            
            testInput.damagoNameChangeSubmitted.send("새이름")
            
            while !isUseCaseExecuted || !isRouteChanged {
                await iterator.next()
            }
        }
        
        #expect(mockUpdateUserUseCase.executeCalled)
        #expect(mockUpdateUserUseCase.lastDamagoName == "새이름")
    }

    @Test("빈 이름을 제출하면 에러 경로가 설정되어야 한다")
    func test_빈이름_제출_시_에러_발생() async {
        // Given
        let mockGlobalStore = MockGlobalStore()
        let mockFetchUserInfoUseCase = mockFetchUserInfoUseCase()
        let mockFeedDamagoUseCase = mockFeedDamagoUseCase()
        let mockPokeDamagoUseCase = mockPokeDamagoUseCase()
        let mockUpdateUserUseCase = mockUpdateUserUseCase()
        
        let viewModel = HomeViewModel(
            globalStore: mockGlobalStore,
            fetchUserInfoUseCase: mockFetchUserInfoUseCase,
            feedDamagoUseCase: mockFeedDamagoUseCase,
            pokeDamagoUseCase: mockPokeDamagoUseCase,
            updateUserUseCase: mockUpdateUserUseCase
        )
        
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        // When & Then
        await confirmation("에러 경로 확인") { confirm in
            let stream = AsyncStream<Void> { continuation in
                output.compactMap { $0.route }
                    .compactMap { $0.value }
                    .filter { if case .error = $0 { return true }; return false }
                    .sink { _ in
                        confirm()
                        continuation.yield()
                    }
                    .store(in: &cancellables)
            }
            var iterator = stream.makeAsyncIterator()
            
            testInput.damagoNameChangeSubmitted.send("   ")
            
            await iterator.next()
        }
        
        #expect(!mockUpdateUserUseCase.executeCalled)
    }
}
