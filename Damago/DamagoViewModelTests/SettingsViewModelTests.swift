//
//  SettingsViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by 박현수 on 2/4/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class SettingsViewModelTests {
    private var cancellables = Set<AnyCancellable>()

    private class FakeGlobalStore: GlobalStoreProtocol {
        private let globalStateSubject = CurrentValueSubject<GlobalState, Never>(.empty)
        var globalState: AnyPublisher<GlobalState, Never> {
            globalStateSubject.eraseToAnyPublisher()
        }

        func updateState(_ state: GlobalState) {
            globalStateSubject.send(state)
        }

        func startMonitoring(uid: String) {}
        func stopMonitoring() {}
    }

    private class SpySignOutUseCase: SignOutUseCase {
        var executeCalled = false
        private let continuation: AsyncStream<Void>.Continuation
        let executedStream: AsyncStream<Void>

        init() {
            var cont: AsyncStream<Void>.Continuation!
            self.executedStream = AsyncStream { cont = $0 }
            self.continuation = cont
        }

        func execute() throws {
            executeCalled = true
            continuation.yield()
        }
    }

    private class SpyWithdrawUseCase: WithdrawUseCase {
        var executeCalled = false
        private let continuation: AsyncStream<Void>.Continuation
        let executedStream: AsyncStream<Void>

        init() {
            var cont: AsyncStream<Void>.Continuation!
            self.executedStream = AsyncStream { cont = $0 }
            self.continuation = cont
        }

        func execute() async throws {
            executeCalled = true
            continuation.yield()
        }
    }

    private class SpyUpdateUserUseCase: UpdateUserUseCase {
        var executeCalled = false
        var lastUseFCM: Bool?
        var lastUseLiveActivity: Bool?
        
        private let continuation: AsyncStream<Void>.Continuation
        let executedStream: AsyncStream<Void>

        init() {
            var cont: AsyncStream<Void>.Continuation!
            self.executedStream = AsyncStream { cont = $0 }
            self.continuation = cont
        }

        func execute(
            nickname: String?,
            anniversaryDate: Date?,
            useFCM: Bool?,
            useLiveActivity: Bool?,
            damagoName: String?,
            damagoType: DamagoType?
        ) async throws {
            executeCalled = true
            self.lastUseFCM = useFCM
            self.lastUseLiveActivity = useLiveActivity
            continuation.yield()
        }
    }

    struct TestInput {
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let toggleChanged = PassthroughSubject<(ToggleType, Bool), Never>()
        let itemSelected = PassthroughSubject<SettingsItem, Never>()
        let damagoBackgroundChanged = PassthroughSubject<DamagoBackgroundColorOption, Never>()
        let alertActionDidConfirm = PassthroughSubject<AlertActionType, Never>()

        var input: SettingsViewModel.Input {
            SettingsViewModel.Input(
                viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
                toggleChanged: toggleChanged.eraseToAnyPublisher(),
                itemSelected: itemSelected.eraseToAnyPublisher(),
                damagoBackgroundChanged: damagoBackgroundChanged.eraseToAnyPublisher(),
                alertActionDidConfirm: alertActionDidConfirm.eraseToAnyPublisher()
            )
        }
    }

    @Test("GlobalState 변화가 ViewModel State에 반영되어야 한다")
    func testGlobalStateBinding() async throws {
        // Given
        let fakeGlobalStore = FakeGlobalStore()
        let viewModel = SettingsViewModel(
            globalStore: fakeGlobalStore,
            signOutUseCase: SpySignOutUseCase(),
            withdrawUseCase: SpyWithdrawUseCase(),
            updateUserUseCase: SpyUpdateUserUseCase()
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        let newState = GlobalState(
            nickname: "TestUser",
            opponentName: "Opponent",
            useFCM: true,
            useLiveActivity: false,
            coupleID: nil, totalCoin: nil, foodCount: nil, anniversaryDate: Date(),
            currentQuestionID: nil, damagoID: nil, damagoName: nil, damagoType: nil,
            level: nil, currentExp: nil, maxExp: nil, isHungry: nil, statusMessage: nil,
            lastFedAt: nil, totalPlayTime: nil, lastActiveAt: nil, ownedDamagos: nil
        )
        

        // When
        testInput.viewDidLoad.send()

        fakeGlobalStore.updateState(newState)
        
        // Then: 1초 내에 "TestUser"가 되는지 확인
        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()

            while let state = await outputIterator.next() {
                if await state.userName == "TestUser" {
                    #expect(state.userName == "TestUser")
                    return
                }
            }
        }
    }

    @Test("설정 아이템 선택 시 적절한 Route가 설정되어야 한다")
    func testItemSelectionRouting() async throws {
        // Given
        let viewModel = SettingsViewModel(
            globalStore: FakeGlobalStore(),
            signOutUseCase: SpySignOutUseCase(),
            withdrawUseCase: SpyWithdrawUseCase(),
            updateUserUseCase: SpyUpdateUserUseCase()
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        // When
        testInput.itemSelected.send(.profile(name: "", dDay: 0, anniversaryDate: ""))
        
        // Then
        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()

            while let state = await outputIterator.next() {
                if let route = await state.route?.value, case .editProfile = route {
                    #expect(true)
                    return
                }
            }
        }
    }
    
    @Test("로그아웃 확인 시 SignOutUseCase가 실행되어야 한다")
    func testSignOutExecution() async throws {
        // Given
        let spySignOutUseCase = SpySignOutUseCase()
        let viewModel = SettingsViewModel(
            globalStore: FakeGlobalStore(),
            signOutUseCase: spySignOutUseCase,
            withdrawUseCase: SpyWithdrawUseCase(),
            updateUserUseCase: SpyUpdateUserUseCase()
        )
        let testInput = TestInput()
        let _ = viewModel.transform(testInput.input)

        // When
        testInput.alertActionDidConfirm.send(.logout)
        
        // Then
        try await withTimeout(seconds: 1.0) {
            var spyIterator = spySignOutUseCase.executedStream.makeAsyncIterator()
            _ = await spyIterator.next()
            #expect(spySignOutUseCase.executeCalled == true)
        }
    }

    @Test("회원탈퇴 확인 시 WithdrawUseCase가 실행되어야 한다")
    func testWithdrawExecution() async throws {
        // Given
        let spyWithdrawUseCase = SpyWithdrawUseCase()
        let viewModel = SettingsViewModel(
            globalStore: FakeGlobalStore(),
            signOutUseCase: SpySignOutUseCase(),
            withdrawUseCase: spyWithdrawUseCase,
            updateUserUseCase: SpyUpdateUserUseCase()
        )
        let testInput = TestInput()
        let _ = viewModel.transform(testInput.input)

        // When
        testInput.alertActionDidConfirm.send(.deleteAccount)
        
        // Then
        try await withTimeout(seconds: 1.0) {
            var spyIterator = spyWithdrawUseCase.executedStream.makeAsyncIterator()
            _ = await spyIterator.next()
            #expect(spyWithdrawUseCase.executeCalled == true)
        }
    }
    
    @Test("토글 OFF 시 UpdateUserUseCase가 호출되어야 한다")
    func testToggleOffUpdatesServer() async throws {
        // Given
        let spyUpdateUserUseCase = SpyUpdateUserUseCase()
        let viewModel = SettingsViewModel(
            globalStore: FakeGlobalStore(),
            signOutUseCase: SpySignOutUseCase(),
            withdrawUseCase: SpyWithdrawUseCase(),
            updateUserUseCase: spyUpdateUserUseCase
        )
        let testInput = TestInput()
        let _ = viewModel.transform(testInput.input)

        // When
        testInput.toggleChanged.send((.notification, false))
        
        // Then
        try await withTimeout(seconds: 1.0) {
            var spyIterator = spyUpdateUserUseCase.executedStream.makeAsyncIterator()
            _ = await spyIterator.next()
            #expect(spyUpdateUserUseCase.executeCalled == true)
            #expect(spyUpdateUserUseCase.lastUseFCM == false)
        }
    }
}
