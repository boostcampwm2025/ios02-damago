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
        var error: Pulse<String>?
        var ownedDamagoTypes: [DamagoType] = []
    }
    
    struct DrawResult: Equatable {
        let id = UUID()
        let itemName: String
        let damagoType: DamagoType
    }
    
    @Published private(set) var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    private let drawCost = 100
    private let globalStore: GlobalStoreProtocol
    
    init(globalStore: GlobalStoreProtocol) {
        self.globalStore = globalStore
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.drawButtonDidTap
            .sink { [weak self] _ in
                self?.tryDraw()
            }
            .store(in: &cancellables)

        globalStore.globalState
            .map { $0.ownedDamagoTypes ?? [] }
            .assign(to: \.state.ownedDamagoTypes, on: self)
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    private func tryDraw() {
        guard state.coinAmount >= drawCost else {
            state.error = Pulse("코인이 부족해요!")
            return
        }
        
        state.coinAmount -= drawCost
        
        let availableDamagos = DamagoType.allCases.filter { !state.ownedDamagoTypes.contains($0) }

        guard let randomDamago = availableDamagos.randomElement() else { return }
        
        let result = DrawResult(itemName: "새로운 친구", damagoType: randomDamago)
        
        state.drawResult = result
    }
}
