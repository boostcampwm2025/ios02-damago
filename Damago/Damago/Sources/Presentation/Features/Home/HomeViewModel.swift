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
        var coinAmount = 0
        var foodAmount = 0
        var dDay = 0
        var petName = ""
        var level = 0
        var currentExp = 0
        var maxExp = 0
        var totalCoin = 0
        var foodCount = 5
        var dDay = 365
        var petName = "모찌"
        var level = 17
        var currentExp = 26
        var maxExp = 100
        var lastFedAt: Date?

        var isFeedButtonEnabled: Bool { foodCount > 0 }
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
            .sink { [weak self] in self?.fetchUserInfo() }
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

                if let damagoID = userInfo.damagoID, let coupleID = userInfo.coupleID {
                    globalStore.startMonitoring(damagoID: damagoID, coupleID: coupleID)
                    bindGlobalState()
                } else {
                    SharedLogger.firebase.error("Missing damagoID or coupleID in UserInfo")
                }

                self.damagoID = userInfo.damagoID
                state.totalCoin = userInfo.totalCoin

                if let petStatus = userInfo.petStatus {
                    state.level = petStatus.level
                    state.currentExp = petStatus.currentExp
                    state.maxExp = petStatus.maxExp
                    state.petName = petStatus.petName
                    
                    if let lastFedAtString = petStatus.lastFedAt {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        state.lastFedAt = formatter.date(from: lastFedAtString) 
                                          ?? ISO8601DateFormatter().date(from: lastFedAtString)
                    }
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
                let success = try await petRepository.feed(damagoID: damagoID)
                if success {
                    state.lastFedAt = Date()
                    LiveActivityManager.shared.synchronizeActivity()
                }
            } catch {
                print("Error feeding pet: \(error)")
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
