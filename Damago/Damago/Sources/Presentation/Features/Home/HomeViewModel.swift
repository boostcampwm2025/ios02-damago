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
    }

    struct State {
        var isLoading = true
        var isFeeding = false
        var coinAmount = 0
        var foodAmount = 0
        var dDay = 0
        var petName = ""
        var level = 0
        var currentExp = 0
        var maxExp = 0
        var totalCoin = 0
        var foodCount = 0
        var lastFedAt: Date?

        var isFeedButtonEnabled: Bool { foodCount > 0 && !isFeeding }
        var isPokeButtonEnabled: Bool { true }
    }

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private var damagoID: String?

    private let globalStore: GlobalStoreProtocol
    private let userRepository: UserRepositoryProtocol
    private let petRepository: PetRepositoryProtocol
    private let pushRepository: PushRepositoryProtocol
    
    init(
        globalStore: GlobalStoreProtocol,
        userRepository: UserRepositoryProtocol,
        petRepository: PetRepositoryProtocol,
        pushRepository: PushRepositoryProtocol
    ) {
        self.globalStore = globalStore
        self.userRepository = userRepository
        self.petRepository = petRepository
        self.pushRepository = pushRepository
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

    private func bindGlobalState() {
        globalStore.petStatus
            .mapForUI { $0.petName }
            .sink { [weak self] in
                self?.state.petName = $0
            }
            .store(in: &cancellables)

        globalStore.petStatus
            .mapForUI { $0.level }
            .sink { [weak self] in
                self?.state.level = $0
            }
            .store(in: &cancellables)

        globalStore.petStatus
            .mapForUI { $0.currentExp }
            .sink { [weak self] in
                self?.state.currentExp = $0
            }
            .store(in: &cancellables)

        globalStore.petStatus
            .mapForUI { $0.maxExp }
            .sink { [weak self] in
                self?.state.maxExp = $0
            }
            .store(in: &cancellables)

        globalStore.coupleSharedInfo
            .mapForUI { $0.foodCount }
            .sink { [weak self] in
                self?.state.foodCount = $0
                self?.state.isFeeding = false
            }
            .store(in: &cancellables)

        globalStore.coupleSharedInfo
            .mapForUI { $0.totalCoin }
            .sink { [weak self] in
                self?.state.totalCoin = $0
            }
            .store(in: &cancellables)
    }
}
