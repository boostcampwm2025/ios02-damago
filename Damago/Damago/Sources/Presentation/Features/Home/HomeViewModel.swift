//
//  HomeViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/7/26.
//

import Combine
import Foundation
import OSLog

final class HomeViewModel: ViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let feedButtonDidTap: AnyPublisher<Void, Never>
        let pokeMessageSelected: AnyPublisher<String, Never>
        let damagoNameChangeSubmitted: AnyPublisher<String, Never>
    }

    struct State: Equatable {
        var isLoading = true
        var isUpdatingName = false
        var isFeeding = false
        var coinAmount = 0
        var foodAmount = 0
        var dDay = 0
        var damagoName = ""
        var damagoType: DamagoType?
        var isHungry: Bool = true
        var level = 0
        var currentExp = 0
        var maxExp = 0
        var totalCoin = 0
        var foodCount = 0
        var lastFedAt: Date?
        var ownedDamagoTypes: [DamagoType] = []

        var isFeedButtonEnabled: Bool { foodCount > 0 && !isFeeding }
        var isPokeButtonEnabled: Bool { true }
        var route: Pulse<Route>?
    }

    enum Route: Equatable {
        case nameChangeSuccess
        case error(message: String)
    }

    @Published private(set) var state = State()
    private var cancellables = Set<AnyCancellable>()
    private var damagoID: String?

    private let globalStore: GlobalStoreProtocol
    private let userRepository: UserRepositoryProtocol
    private let damagoRepository: DamagoRepositoryProtocol
    private let pushRepository: PushRepositoryProtocol
    private let updateUserUseCase: UpdateUserUseCase
    
    init(
        globalStore: GlobalStoreProtocol,
        userRepository: UserRepositoryProtocol,
        damagoRepository: DamagoRepositoryProtocol,
        pushRepository: PushRepositoryProtocol,
        updateUserUseCase: UpdateUserUseCase
    ) {
        self.globalStore = globalStore
        self.userRepository = userRepository
        self.damagoRepository = damagoRepository
        self.pushRepository = pushRepository
        self.updateUserUseCase = updateUserUseCase
    }

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.fetchUserInfo()
                self?.bindGlobalState()
            }
            .store(in: &cancellables)

        input.feedButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.feedDamago() }
            .store(in: &cancellables)

        input.pokeMessageSelected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.pokeDamago(with: message)
            }
            .store(in: &cancellables)

        input.damagoNameChangeSubmitted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.updateDamagoName(name: name)
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }
    
    private func fetchUserInfo() {
        state.isLoading = true
        Task {
            defer {
                state.isLoading = false
            }
            do {
                let userInfo = try await userRepository.getUserInfo()

                self.damagoID = userInfo.damagoID
                state.totalCoin = userInfo.totalCoin

                if let damagoStatus = userInfo.damagoStatus {
                    state.level = damagoStatus.level
                    state.currentExp = damagoStatus.currentExp
                    state.maxExp = damagoStatus.maxExp
                    state.damagoName = damagoStatus.damagoName
                    state.damagoType = damagoStatus.damagoType
                    state.isHungry = damagoStatus.isHungry
                    state.lastFedAt = damagoStatus.lastFedAt
                }
            } catch {
                print("Error fetching user info: \(error)")
            }
        }
    }

    private func feedDamago() {
        guard let damagoID else { return }
        
        Task {
            do {
                state.isFeeding = true
                let success = try await damagoRepository.feed(damagoID: damagoID)
                if success {
                    state.lastFedAt = Date()
                    LiveActivityManager.shared.synchronizeActivity()
                } else {
                    state.isFeeding = false
                }
            } catch {
                print("Error feeding damago: \(error)")
                state.isFeeding = false
            }
        }
    }

    private func pokeDamago(with message: String) {
        Task {
            do {
                _ = try await pushRepository.poke(message: message)
                print("Poke sent with message: \(message)")
            } catch {
                print("Error poking damago: \(error)")
            }
        }
    }

    private func updateDamagoName(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state.route = Pulse(.error(message: "이름을 입력해 주세요."))
            return
        }

        Task {
            state.isUpdatingName = true
            defer { state.isUpdatingName = false }
            do {
                try await updateUserUseCase.execute(
                    nickname: nil,
                    anniversaryDate: nil,
                    useFCM: nil,
                    useLiveActivity: nil,
                    damagoName: trimmed,
                    damagoType: nil
                )
                // 서버/Firestore 반영을 기다리지 않고 UI를 즉시 갱신
                state.damagoName = trimmed
                state.route = Pulse(.nameChangeSuccess)
            } catch {
                state.route = Pulse(.error(message: error.userFriendlyMessage))
            }
        }
    }

    private func bindGlobalState() {
        globalStore.globalState
            .compactMap { $0.damagoID }
            .sink { [weak self] in self?.damagoID = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0 }
            .sink { [weak self] state in
                guard let self, let damagoType = state.damagoType, let isHungry = state.isHungry else { return }
                
                self.state.damagoType = damagoType
                self.state.isHungry = isHungry
            }
            .store(in: &cancellables)
        
        globalStore.globalState
            .map { $0.ownedDamagoTypes ?? [] }
            .assign(to: \.state.ownedDamagoTypes, on: self)
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.damagoName }
            .sink { [weak self] in self?.state.damagoName = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.level }
            .sink { [weak self] in self?.state.level = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMap { $0.currentExp }
            .sink { [weak self] in self?.state.currentExp = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.maxExp }
            .sink { [weak self] in self?.state.maxExp = $0 }
            .store(in: &cancellables)
            
        globalStore.globalState
            .mapForUI { $0.lastFedAt }
            .sink { [weak self] in self?.state.lastFedAt = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.foodCount }
            .sink { [weak self] in
                self?.state.foodCount = $0
                self?.state.isFeeding = false
            }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.totalCoin }
            .sink { [weak self] in self?.state.totalCoin = $0 }
            .store(in: &cancellables)

        globalStore.globalState
            .mapForUI { $0.anniversaryDate }
            .sink { [weak self] anniversaryDate in
                if let anniversaryDate = anniversaryDate {
                    self?.state.dDay = anniversaryDate.daysBetween(to: Date()) ?? 0
                } else {
                    self?.state.dDay = 0
                }
            }
            .store(in: &cancellables)
    }
}
