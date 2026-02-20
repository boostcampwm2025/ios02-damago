//
//  StoreViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/28/26.
//

import Combine
import Foundation

final class StoreViewModel: ViewModel {
    enum StorePolicy {
        static let drawCost = 100
    }
    
    enum StoreStrings {
        static let notEnoughCoinLabel = "코인이 부족해요"
        static func drawButtonTitle(cost: Int) -> String { "\(cost) 코인" }
    }
    
    struct Input {
        let drawButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State {
        var coinAmount: Int = 0
        var drawResult: DrawResult?
        var error: Pulse<StoreError>?
        var ownedDamagos: [DamagoType: Int] = [:]
        var isLoading: Bool = false
        
        var isDrawButtonEnabled: Bool {
            let isCoinEnough = coinAmount >= StorePolicy.drawCost
            return isCoinEnough && !isLoading
        }
        
        var drawButtonTitle: String {
             if coinAmount < StorePolicy.drawCost {
                 return StoreStrings.notEnoughCoinLabel
             }
             return StoreStrings.drawButtonTitle(cost: StorePolicy.drawCost)
        }
    }
    
    @Published private(set) var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    private let globalStore: GlobalStoreProtocol
    private let createDamagoUseCase: CreateDamagoUseCase
    
    init(
        globalStore: GlobalStoreProtocol,
        createDamagoUseCase: CreateDamagoUseCase
    ) {
        self.globalStore = globalStore
        self.createDamagoUseCase = createDamagoUseCase
    }
    
    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.drawButtonDidTap
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                self?.tryDraw()
            }
            .store(in: &cancellables)
        
        globalStore.globalState
            .map { $0.ownedDamagos ?? [:] }
            .assign(to: \.state.ownedDamagos, on: self)
            .store(in: &cancellables)
        
        globalStore.globalState
            .map { $0.totalCoin ?? 0 }
            .assign(to: \.state.coinAmount, on: self)
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    private func tryDraw() {
        guard state.coinAmount >= StorePolicy.drawCost else {
            state.error = Pulse(.notEnoughCoin)
            return
        }
        
        state.isLoading = true
        Task {
            defer { state.isLoading = false }
            do {
                state.drawResult = try await createDamagoUseCase.execute()
            } catch {
                state.error = Pulse(.creationFailed)
            }
        }
    }
}
