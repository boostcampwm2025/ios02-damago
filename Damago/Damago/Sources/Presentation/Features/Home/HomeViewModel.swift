//
//  HomeViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/7/26.
//

import Combine
import Foundation

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
        var lastFedAt: Date?

        var isFeedButtonEnabled: Bool { foodAmount > 0 }
        var isPokeButtonEnabled: Bool { true }
    }

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private var damagoID: String?
    
    private let userRepository: UserRepositoryProtocol
    private let petRepository: PetRepositoryProtocol
    private let pushRepository: PushRepositoryProtocol
    
    init(
        userRepository: UserRepositoryProtocol,
        petRepository: PetRepositoryProtocol,
        pushRepository: PushRepositoryProtocol
    ) {
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
                Task { @MainActor in
                    state.isLoading = false
                }
            }
            do {
                let userInfo = try await userRepository.getUserInfo()
                state.coinAmount = userInfo.totalCoin
                self.damagoID = userInfo.damagoID
                
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
}
