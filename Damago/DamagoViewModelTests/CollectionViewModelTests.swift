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

    private final class SpyUpdateUserUseCase: UpdateUserUseCase {
        var executeCalled = false
        var lastDamagoType: DamagoType?
        var shouldFail = false
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
            lastDamagoType = damagoType
            onExecute?()
            
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            if shouldFail {
                throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
            }
        }
    }

    private final class FakeFetchUserInfoUseCase: FetchUserInfoUseCase {
        private let result: Result<UserInfo, Error>
        var onExecute: (() -> Void)?

        init(result: Result<UserInfo, Error>) {
            self.result = result
        }

        func execute() async throws -> UserInfo {
            onExecute?()
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
        let fetchUseCase = FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: damagoType)))
        let viewModel = CollectionViewModel(
            updateUserUseCase: SpyUpdateUserUseCase(),
            fetchUserInfoUseCase: fetchUseCase,
            globalStore: FakeGlobalStore()
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)

        await confirmation("현재 다마고 타입이 업데이트되어야 함") { confirm in
            let stateStream = AsyncStream<DamagoType?> { continuation in
                output.map { $0.currentDamagoType }
                    .removeDuplicates()
                    .sink { continuation.yield($0) }
                    .store(in: &cancellables)
            }
            var iterator = stateStream.makeAsyncIterator()

            testInput.viewDidLoad.send()
            
            while let current = await iterator.next() {
                if current == damagoType {
                    confirm()
                    break
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

        await confirmation("보유 다마고 목록이 업데이트되어야 함") { confirm in
            let ownedStream = AsyncStream<[DamagoType: Int]> { continuation in
                output.map { $0.ownedDamagos }
                    .removeDuplicates()
                    .sink { continuation.yield($0) }
                    .store(in: &cancellables)
            }
            var iterator = ownedStream.makeAsyncIterator()

            globalStore.updateState(Self.makeGlobalState(owned: owned))
            
            while let currentOwned = await iterator.next() {
                if currentOwned == owned {
                    confirm()
                    break
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

        await confirmation("변경 확인 팝업이 노출되어야 함") { confirm in
            let routeStream = AsyncStream<CollectionViewModel.Route?> { continuation in
                output.map { $0.route?.value }
                    .removeDuplicates()
                    .sink { continuation.yield($0) }
                    .store(in: &cancellables)
            }
            var iterator = routeStream.makeAsyncIterator()

            testInput.viewDidLoad.send()
            globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 2]))
            testInput.damagoSelected.send(targetDamago)
            
            while let route = await iterator.next() {
                if case let .showChangeConfirmPopup(damagoType) = route, damagoType == targetDamago {
                    confirm()
                    break
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

        await confirmation("에러 라우트가 발생해야 함") { confirm in
            let routeStream = AsyncStream<CollectionViewModel.Route?> { continuation in
                output.map { $0.route?.value }
                    .removeDuplicates()
                    .sink { continuation.yield($0) }
                    .store(in: &cancellables)
            }
            var iterator = routeStream.makeAsyncIterator()

            testInput.viewDidLoad.send()
            globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1]))
            testInput.damagoSelected.send(.siamese)
            
            while let route = await iterator.next() {
                if case let .error(title, message) = route {
                    if title == "미보유 다마고입니다." && message == "코인을 모아 상점해서 획득해보세요!" {
                        confirm()
                        break
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

        await confirmation("UpdateUserUseCase가 호출되고 상태가 업데이트되어야 함", expectedCount: 2) { confirm in
            let stateStream = AsyncStream<DamagoType?> { continuation in
                output.map { $0.currentDamagoType }
                    .removeDuplicates()
                    .sink { continuation.yield($0) }
                    .store(in: &cancellables)
            }
            var iterator = stateStream.makeAsyncIterator()
            
            let useCaseStream = AsyncStream<Void> { continuation in
                updateUseCase.onExecute = {
                    confirm()
                    continuation.yield()
                }
            }
            var useCaseIterator = useCaseStream.makeAsyncIterator()

            testInput.viewDidLoad.send()
            globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 1]))
            testInput.damagoSelected.send(targetDamago)
            
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            testInput.confirmChangeTapped.send()
            
            // 1. UseCase 실행 대기
            await useCaseIterator.next()
            
            // 2. 상태 업데이트 대기
            while let current = await iterator.next() {
                if current == targetDamago {
                    confirm()
                    break
                }
            }
        }
    }

    @Test("현재 다마고와 동일한 타입 선택 시 라우트가 발생하지 않는다")
    func testSelectSameAsCurrentDoesNotEmitRoute() async throws {
        let globalStore = FakeGlobalStore()
        let fetchUseCase = FakeFetchUserInfoUseCase(result: .success(Self.makeUserInfo(damagoType: .basicBlack)))
        let viewModel = CollectionViewModel(
            updateUserUseCase: SpyUpdateUserUseCase(),
            fetchUserInfoUseCase: fetchUseCase,
            globalStore: globalStore
        )
        let testInput = TestInput()
        let output = viewModel.transform(testInput.input)
        
        await confirmation("초기 다마고 로드 완료") { confirm in
            let stateStream = AsyncStream<DamagoType?> { continuation in
                output.map { $0.currentDamagoType }
                    .removeDuplicates()
                    .sink { continuation.yield($0) }
                    .store(in: &cancellables)
            }
            var iterator = stateStream.makeAsyncIterator()
            
            testInput.viewDidLoad.send()
            while let current = await iterator.next() {
                if current == .basicBlack {
                    confirm()
                    break
                }
            }
        }
        
        var routeEmitted = false
        output.compactMap { $0.route }
            .sink { _ in routeEmitted = true }
            .store(in: &cancellables)
        
        globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 1]))
        testInput.damagoSelected.send(.basicBlack)
        
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(routeEmitted == false)
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

        await confirmation("로딩 상태가 true였다가 false로 돌아와야 함", expectedCount: 2) { confirm in
            let loadingStream = AsyncStream<Bool> { continuation in
                output.map { $0.isLoading }
                    .removeDuplicates()
                    .sink { continuation.yield($0) }
                    .store(in: &cancellables)
            }
            var iterator = loadingStream.makeAsyncIterator()

            testInput.viewDidLoad.send()
            globalStore.updateState(Self.makeGlobalState(owned: [.basicBlack: 1, .siamese: 1]))
            testInput.damagoSelected.send(.siamese)
            
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            // 초기 false 소비
            _ = await iterator.next()
            
            testInput.confirmChangeTapped.send()
            
            // 1. Loading True 대기
            if let first = await iterator.next(), first == true {
                confirm()
            }
            
            // 2. Loading False 대기
            if let second = await iterator.next(), second == false {
                confirm()
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
            todayPokeCount: 0,
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
