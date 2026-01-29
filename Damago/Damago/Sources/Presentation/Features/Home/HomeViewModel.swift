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
        let petNameChangeSubmitted: AnyPublisher<String, Never>
    }

    struct State: Equatable {
        var isLoading = true
        var isUpdatingName = false
        var isFeeding = false
        var coinAmount = 0
        var foodAmount = 0
        var dDay = 0
        var petName = ""
        var petType = ""
        var isHungry: Bool = true
        var level = 0
        var currentExp = 0
        var maxExp = 0
        var totalCoin = 0
        var foodCount = 0
        var lastFedAt: Date?

        var isFeedButtonEnabled: Bool { foodCount > 0 && !isFeeding }
        var isPokeButtonEnabled: Bool { true }
        var route: Pulse<Route>?
    }

    enum Route: Equatable {
        case nameChangeSuccess
        case error(message: String)
    }

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private var damagoID: String?

    private let globalStore: GlobalStoreProtocol
    private let userRepository: UserRepositoryProtocol
    private let petRepository: PetRepositoryProtocol
    private let pushRepository: PushRepositoryProtocol
    private let updateUserUseCase: UpdateUserUseCase
    
    init(
        globalStore: GlobalStoreProtocol,
        userRepository: UserRepositoryProtocol,
        petRepository: PetRepositoryProtocol,
        pushRepository: PushRepositoryProtocol,
        updateUserUseCase: UpdateUserUseCase
    ) {
        self.globalStore = globalStore
        self.userRepository = userRepository
        self.petRepository = petRepository
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
            .sink { [weak self] in self?.feedPet() }
            .store(in: &cancellables)

        input.pokeMessageSelected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.pokePet(with: message)
            }
            .store(in: &cancellables)

        input.petNameChangeSubmitted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.updatePetName(name: name)
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

                if let petStatus = userInfo.petStatus {
                    state.level = petStatus.level
                    state.currentExp = petStatus.currentExp
                    state.maxExp = petStatus.maxExp
                    state.petName = petStatus.petName
                    state.petType = petStatus.petType
                    state.isHungry = petStatus.isHungry
                    state.lastFedAt = petStatus.lastFedAt
                }
            } catch {
                print("Error fetching user info: \(error)")
            }
        }
    }

    private func feedPet() {
        guard let damagoID else { return }
        
        Task {
            do {
                state.isFeeding = true
                let success = try await petRepository.feed(damagoID: damagoID)
                if success {
                    state.lastFedAt = Date()
                    LiveActivityManager.shared.synchronizeActivity()
                } else {
                    state.isFeeding = false
                }
            } catch {
                print("Error feeding pet: \(error)")
                state.isFeeding = false
            }
        }
    }

    private func pokePet(with message: String) {
        Task {
            do {
                _ = try await pushRepository.poke(message: message)
                print("Poke sent with message: \(message)")
            } catch {
                print("Error poking pet: \(error)")
            }
        }
    }

    private func updatePetName(name: String) {
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
                    petName: trimmed,
                    petType: nil
                )
                // 서버/Firestore 반영을 기다리지 않고 UI를 즉시 갱신
                state.petName = trimmed
                state.route = Pulse(.nameChangeSuccess)
            } catch {
                state.route = Pulse(.error(message: error.userFriendlyMessage))
            }
        }
    }

    private func bindGlobalState() {
        globalStore.globalState
            .compactMapForUI { $0 }
            .sink { [weak self] state in
                guard let self, let petType = state.petType, let isHungry = state.isHungry else { return }
                
                self.state.petType = petType
                self.state.isHungry = isHungry
            }
            .store(in: &cancellables)

        globalStore.globalState
            .compactMapForUI { $0.petName }
            .sink { [weak self] in self?.state.petName = $0 }
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
