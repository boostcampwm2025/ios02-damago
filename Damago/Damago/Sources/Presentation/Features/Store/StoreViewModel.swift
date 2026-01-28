//
//  StoreViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/28/26.
//

import Combine
import Foundation

final class StoreViewModel: ViewModel {
    struct Input {
        let drawButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State {
        var coinAmount: Int = 1000
        var drawResult: DrawResult?
        var error: String?
    }
    
    struct DrawResult: Equatable {
        let itemName: String
        let petType: DamagoType
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    private let drawCost = 100
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.drawButtonDidTap
            .sink { [weak self] _ in
                self?.tryDraw()
            }
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    private func tryDraw() {
        guard state.coinAmount >= drawCost else {
            state.error = "코인이 부족해요!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.state.error = nil
            }
            return
        }
        
        state.coinAmount -= drawCost
        
        let availablePets = DamagoType.allCases.filter { $0.isAvailable }
        guard let randomPet = availablePets.randomElement() else { return }
        
        let result = DrawResult(itemName: "새로운 친구", petType: randomPet)
        
        state.drawResult = result
    }
}
