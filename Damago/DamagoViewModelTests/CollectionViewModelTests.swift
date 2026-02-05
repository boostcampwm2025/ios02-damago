//
//  CollectionViewModelTests.swift
//  DamagoViewModelTests
//
//  Created by loyH on 2/4/26.
//

import Testing
import Combine
import Foundation
@testable import Damago

@MainActor
final class CollectionViewModelTests {
    private var cancellables = Set<AnyCancellable>()

    private final class FakeGlobalStore: GlobalStoreProtocol {
        private let globalStateSubject = CurrentValueSubject<GlobalState, Never>(
            GlobalState(
                nickname: nil,
                opponentName: nil,
                useFCM: false,
                useLiveActivity: false,
                coupleID: nil,
                totalCoin: nil,
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
                ownedDamagos: [:]
            )
        )

        var globalState: AnyPublisher<GlobalState, Never> {
            globalStateSubject.eraseToAnyPublisher()
        }

        func updateState(_ state: GlobalState) {
            globalStateSubject.send(state)
        }

        func startMonitoring(uid: String) {}
        func stopMonitoring() {}
    }

    private final class SpyUpdateUserUseCase: UpdateUserUseCase {
        var executeCalled = false
        var lastDamagoType: DamagoType?
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
            lastDamagoType = damagoType
            continuation.yield()
            if shouldFail {
                throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
            }
        }
    }

    private final class FakeFetchUserInfoUseCase: FetchUserInfoUseCase {
        private let result: Result<UserInfo, Error>

        init(result: Result<UserInfo, Error>) {
            self.result = result
        }

        func execute() async throws -> UserInfo {
            switch result {
            case let .success(userInfo):
                return userInfo
            case let .failure(error):
                throw error
            }
        }
    }

    struct TestInput {
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let damagoSelected = PassthroughSubject<DamagoType, Never>()
        let confirmChangeTapped = PassthroughSubject<Void, Never>()

        var input: CollectionViewModel.Input {
            CollectionViewModel.Input(
                viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
                damagoSelected: damagoSelected.eraseToAnyPublisher(),
                confirmChangeTapped: confirmChangeTapped.eraseToAnyPublisher()
            )
        }
    }

    @Test("viewDidLoad 시 현재 다마고 타입을 불러온다")
    func testLoadCurrentDamagoOnViewDidLoad() async throws {
        let damagoType: DamagoType = .basicBlack
        let viewModel = CollectionViewModel(
            updateUserUseCase: SpyUpdateUserUseCase(),
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: damagoType))),
            globalStore: FakeGlobalStore()
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        testInput.viewDidLoad.send()

        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()
            while let state = await outputIterator.next() {
                if await state.currentDamagoType == damagoType {
                    #expect(state.currentDamagoType == damagoType)
                    return
                }
            }
        }
    }

    @Test("GlobalStore의 ownedDamagos가 상태에 반영된다")
    func testOwnedDamagosFromGlobalStore() async throws {
        let globalStore = FakeGlobalStore()
        let viewModel = CollectionViewModel(
            updateUserUseCase: SpyUpdateUserUseCase(),
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .failure(TestError.dummy)),
            globalStore: globalStore
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        let owned: [DamagoType: Int] = [.basicBlack: 3, .siamese: 1]

        globalStore.updateState(Self.makeGlobalState(owned: owned))

        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()
            while let state = await outputIterator.next() {
                if await state.ownedDamagos == owned {
                    #expect(state.ownedDamagos == owned)
                    return
                }
            }
        }
    }

    @Test("보유 다마고 선택 시 변경 확인 팝업을 노출한다")
    func testSelectOwnedDamagoShowsConfirmPopup() async throws {
        let globalStore = FakeGlobalStore()
        let viewModel = CollectionViewModel(
            updateUserUseCase: SpyUpdateUserUseCase(),
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: .basicBlack))),
            globalStore: globalStore
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        let targetDamago: DamagoType = .siamese

        testInput.viewDidLoad.send()
        globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 2]))
        testInput.damagoSelected.send(targetDamago)

        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()
            while let state = await outputIterator.next() {
                if let route = await state.route?.value, case let .showChangeConfirmPopup(damagoType) = route {
                    if damagoType == targetDamago {
                        #expect(damagoType == targetDamago)
                        return
                    }
                }
            }
        }
    }

    @Test("미보유 다마고 선택 시 에러 라우트가 발생한다")
    func testSelectUnownedDamagoShowsError() async throws {
        let globalStore = FakeGlobalStore()
        let viewModel = CollectionViewModel(
            updateUserUseCase: SpyUpdateUserUseCase(),
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: .basicBlack))),
            globalStore: globalStore
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        testInput.viewDidLoad.send()
        globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1]))
        testInput.damagoSelected.send(.siamese)

        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()
            while let state = await outputIterator.next() {
                if let route = await state.route?.value, case let .error(title, message) = route {
                    if title == "미보유 다마고입니다." && message == "코인을 모아 상점해서 획득해보세요!" {
                        #expect(true)
                        return
                    }
                }
            }
        }
    }

    @Test("변경 확정 시 UpdateUserUseCase가 호출되고 현재 다마고 타입이 갱신된다")
    func testConfirmChangeUpdatesCurrentDamago() async throws {
        let updateUseCase = SpyUpdateUserUseCase()
        let globalStore = FakeGlobalStore()
        let viewModel = CollectionViewModel(
            updateUserUseCase: updateUseCase,
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: .basicBlack))),
            globalStore: globalStore
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        let targetDamago: DamagoType = .siamese

        testInput.viewDidLoad.send()
        globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 1]))
        testInput.damagoSelected.send(targetDamago)
        testInput.confirmChangeTapped.send()

        try await withTimeout(seconds: 1.0) {
            var spyIterator = updateUseCase.executedStream.makeAsyncIterator()
            _ = await spyIterator.next()
            #expect(updateUseCase.executeCalled == true)
            #expect(updateUseCase.lastDamagoType == targetDamago)
        }

        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()
            while let state = await outputIterator.next() {
                if await state.currentDamagoType == targetDamago {
                    #expect(state.currentDamagoType == targetDamago)
                    return
                }
            }
        }
    }

    @Test("현재 다마고와 동일한 타입 선택 시 라우트가 발생하지 않는다")
    func testSelectSameAsCurrentDoesNotEmitRoute() async throws {
        let globalStore = FakeGlobalStore()
        let viewModel = CollectionViewModel(
            updateUserUseCase: SpyUpdateUserUseCase(),
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: .basicBlack))),
            globalStore: globalStore
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        var currentDamagoType: DamagoType?
        var routeCount = 0
        output
            .sink { state in
                currentDamagoType = state.currentDamagoType
                if state.route != nil {
                    routeCount += 1
                }
            }
            .store(in: &cancellables)

        testInput.viewDidLoad.send()
        globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 1]))

        for _ in 0..<20 {
            let currentType = await MainActor.run { currentDamagoType }
            if currentType == .basicBlack {
                break
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        let initialRouteCount = await MainActor.run { routeCount }
        testInput.damagoSelected.send(.basicBlack)
        try await Task.sleep(nanoseconds: 200_000_000)
        let finalRouteCount = await MainActor.run { routeCount }
        #expect(finalRouteCount == initialRouteCount)
    }

    @Test("선택된 다마고가 없으면 변경 확정을 눌러도 호출되지 않는다")
    func testConfirmChangeWithoutSelectionDoesNothing() async throws {
        let updateUseCase = SpyUpdateUserUseCase()
        let viewModel = CollectionViewModel(
            updateUserUseCase: updateUseCase,
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: .basicBlack))),
            globalStore: FakeGlobalStore()
        )
        let testInput = TestInput()
        _ = viewModel.transform(testInput.input)

        testInput.confirmChangeTapped.send()

        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(updateUseCase.executeCalled == false)
    }

    @Test("변경 실패 시 에러 라우트가 설정된다")
    func testConfirmChangeFailureEmitsErrorRoute() async throws {
        let updateUseCase = SpyUpdateUserUseCase()
        updateUseCase.shouldFail = true
        let globalStore = FakeGlobalStore()
        let viewModel = CollectionViewModel(
            updateUserUseCase: updateUseCase,
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: .basicBlack))),
            globalStore: globalStore
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        testInput.viewDidLoad.send()
        globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 1]))
        testInput.damagoSelected.send(.siamese)
        testInput.confirmChangeTapped.send()

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

    @Test("변경 요청 시 로딩 상태가 토글된다")
    func testChangeDamagoLoadingState() async throws {
        let updateUseCase = SpyUpdateUserUseCase()
        let globalStore = FakeGlobalStore()
        let viewModel = CollectionViewModel(
            updateUserUseCase: updateUseCase,
            fetchUserInfoUseCase: FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: .basicBlack))),
            globalStore: globalStore
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        testInput.viewDidLoad.send()
        globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 1]))
        testInput.damagoSelected.send(.siamese)
        testInput.confirmChangeTapped.send()

        try await withTimeout(seconds: 1.0) {
            var outputIterator = output.values.makeAsyncIterator()
            var sawLoadingTrue = false
            while let state = await outputIterator.next() {
                if await state.isLoading {
                    sawLoadingTrue = true
                }
                if sawLoadingTrue, await state.isLoading == false {
                    #expect(true)
                    return
                }
            }
        }
    }

    private static func makeUserInfo(damagoType: DamagoType) -> UserInfo {
        UserInfo(
            uid: "uid",
            damagoID: "damagoID",
            coupleID: nil,
            partnerUID: nil,
            nickname: "닉네임",
            damagoStatus: DamagoStatus(
                damagoName: "냥이",
                damagoType: damagoType,
                level: 1,
                currentExp: 0,
                maxExp: 10,
                isHungry: false,
                statusMessage: "",
                lastFedAt: nil,
                totalPlayTime: 0,
                lastActiveAt: nil
            ),
            totalCoin: 0,
            lastFedAt: nil
        )
    }

    private static func makeGlobalState(owned: [DamagoType: Int]) -> GlobalState {
        GlobalState(
            nickname: nil,
            opponentName: nil,
            useFCM: false,
            useLiveActivity: false,
            coupleID: nil,
            totalCoin: nil,
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
            ownedDamagos: owned
        )
    }
}
