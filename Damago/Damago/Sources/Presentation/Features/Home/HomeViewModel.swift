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
    
    init(udid: String?) {
        self.udid = udid
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
        Task {
            guard let url = URL(string: "\(BaseURL.string)/get_user_info") else { return }
            
            var request = URLRequest(url: url)
            let body = ["udid": udid]
            
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    return
                }
                
                let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
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
        Task {
            guard let damagoID = damagoID else { return }
            guard let url = URL(string: "\(BaseURL.string)/feed") else { return }

            var request = URLRequest(url: url)
            let body = ["damagoID": damagoID]

            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else { return }
                if (200..<300).contains(httpResponse.statusCode) {
                    state.lastFedAt = Date()
                }
            } catch {
                print("Error feeding pet: \(error)")
            }
        }
    }
}
