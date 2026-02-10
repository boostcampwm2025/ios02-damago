//
//  EditProfileViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by 박현수 on 2/4/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class EditProfileViewModelTests {
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

    private class SpyUpdateUserUseCase: UpdateUserUseCase {
        var executeCalled = false
        var lastNickname: String?
        var lastAnniversaryDate: Date?
        var shouldFail = false
        
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
            self.lastNickname = nickname
            self.lastAnniversaryDate = anniversaryDate
            
            if shouldFail {
                continuation.yield()
                throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
            }
            
            continuation.yield()
        }
    }

    struct TestInput {
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let nicknameChanged = PassthroughSubject<String, Never>()
        let dateChanged = PassthroughSubject<Date, Never>()
        let saveButtonDidTap = PassthroughSubject<Void, Never>()

        var input: EditProfileViewModel.Input {
            EditProfileViewModel.Input(
                viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
                nicknameChanged: nicknameChanged.eraseToAnyPublisher(),
                dateChanged: dateChanged.eraseToAnyPublisher(),
                saveButtonDidTap: saveButtonDidTap.eraseToAnyPublisher()
            )
        }
    }

    @Test("GlobalState의 닉네임과 기념일이 ViewModel State에 반영되어야 한다")
    func testGlobalStateBinding() async throws {
        // Given
        let fakeGlobalStore = FakeGlobalStore()
        let viewModel = EditProfileViewModel(
            globalStore: fakeGlobalStore,
            updateUserUseCase: SpyUpdateUserUseCase()
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        let testDate = Date(timeIntervalSince1970: 1000)
        let newState = GlobalState(
            nickname: "InitialName",
            opponentName: nil,
            useFCM: false,
            useLiveActivity: false, todayPokeCount: 0,
            coupleID: nil, totalCoin: nil, foodCount: nil,
            anniversaryDate: testDate,
            currentQuestionID: nil, damagoID: nil, damagoName: nil, damagoType: nil,
            level: nil, currentExp: nil, maxExp: nil, isHungry: nil, statusMessage: nil,
            lastFedAt: nil, totalPlayTime: nil, lastActiveAt: nil, ownedDamagos: nil
        )

        // When
        testInput.viewDidLoad.send()
        fakeGlobalStore.updateState(newState)

        // Then
        try await withTimeout(seconds: 1.0) { @MainActor in
            var outputIterator = output.values.makeAsyncIterator()

            while let state = await outputIterator.next() {
                if state.nickname == "InitialName" && state.anniversaryDate == testDate {
                    #expect(state.nickname == "InitialName")
                    #expect(state.anniversaryDate == testDate)
                    return
                }
            }
        }
    }

    @Test("닉네임 변경 입력이 State에 반영되어야 한다")
    func testNicknameChange() async throws {
        // Given
        let viewModel = EditProfileViewModel(
            globalStore: FakeGlobalStore(),
            updateUserUseCase: SpyUpdateUserUseCase()
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        // When
        testInput.nicknameChanged.send("NewNickname")

        // Then
        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()

            while let state = await outputIterator.next() {
                if await state.nickname == "NewNickname" {
                    #expect(state.nickname == "NewNickname")
                    #expect(state.isSaveEnabled == true)
                    return
                }
            }
        }
    }

    @Test("저장 버튼 클릭 시 UpdateUserUseCase가 호출되고 back으로 이동해야 한다")
    func testSaveProfileSuccess() async throws {
        // Given
        let spyUpdateUserUseCase = SpyUpdateUserUseCase()
        let viewModel = EditProfileViewModel(
            globalStore: FakeGlobalStore(),
            updateUserUseCase: spyUpdateUserUseCase
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        let newNickname = "UpdatedName"
        let newDate = Date()

        // When
        testInput.nicknameChanged.send(newNickname)
        testInput.dateChanged.send(newDate)
        testInput.saveButtonDidTap.send()

        // Then: UseCase 호출 확인
        try await withTimeout(seconds: 1.0) {
            var spyIterator = spyUpdateUserUseCase.executedStream.makeAsyncIterator()
            _ = await spyIterator.next()
            #expect(spyUpdateUserUseCase.executeCalled == true)
            #expect(spyUpdateUserUseCase.lastNickname == newNickname)
            #expect(spyUpdateUserUseCase.lastAnniversaryDate == newDate)
        }

        // Then: Route 확인
        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()
            while let state = await outputIterator.next() {
                if let route = await state.route?.value, case .back = route {
                    #expect(true)
                    return
                }
            }
        }
    }

    @Test("저장 실패 시 에러 루트가 설정되어야 한다")
    func testSaveProfileFailure() async throws {
        // Given
        let spyUpdateUserUseCase = SpyUpdateUserUseCase()
        spyUpdateUserUseCase.shouldFail = true
        let viewModel = EditProfileViewModel(
            globalStore: FakeGlobalStore(),
            updateUserUseCase: spyUpdateUserUseCase
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        // When
        testInput.nicknameChanged.send("SomeName")
        testInput.saveButtonDidTap.send()

        // Then: Error Route 확인
        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()
            while let state = await outputIterator.next() {
                if let route = await state.route?.value, case .error = route {
                    #expect(true)
                    return
                }
            }
        }
    }
}
