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
        let pokeButtonDidTap: AnyPublisher<Void, Never>
    }

    struct State {
        var coinAmount = 1000
        var foodAmount = 5
        var dDay = 365
        var petName = "모찌"
        var level = 17
        var currentExp = 26
        var maxExp = 100
        var lastFedAt: Date?

        var isFeedButtonEnabled: Bool { foodAmount > 0 }
        var isPokeButtonEnabled: Bool { true }
    }

    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    private var damagoID: String?
    private let udid: String?
    
    private let userRepository: UserRepositoryProtocol
    private let petRepository: PetRepositoryProtocol
    
    init(
        udid: String?,
        userRepository: UserRepositoryProtocol,
        petRepository: PetRepositoryProtocol
    ) {
        self.udid = udid
        self.userRepository = userRepository
        self.petRepository = petRepository
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

        input.pokeButtonDidTap
            .sink { }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }
    
    private func fetchUserInfo() {
        guard let udid = udid else { return }
        
        Task {
            do {
                let userInfo = try await userRepository.getUserInfo(udid: udid)
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
}
