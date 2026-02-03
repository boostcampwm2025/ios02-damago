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
        var coinAmount: Int = 0
        var drawResult: DrawResult?
        var error: Pulse<String>?
        var ownedDamagos: [DamagoType: Int] = [:]
        var isLoading: Bool = false
        
        var isDrawButtonEnabled: Bool {
            let isCoinEnough = coinAmount >= StoreViewModel.drawCost
            let isCollectionComplete = DamagoType.allCases.allSatisfy { ownedDamagos.keys.contains($0) }
            return isCoinEnough && !isCollectionComplete && !isLoading
        }
        
        var drawButtonTitle: String {
             let isCollectionComplete = DamagoType.allCases.allSatisfy { ownedDamagos.keys.contains($0) }
             if isCollectionComplete {
                 return "모든 친구 수집 완료!"
             }
             if coinAmount < StoreViewModel.drawCost {
                 return "코인이 부족해요"
             }
             return "\(StoreViewModel.drawCost) 코인"
        }
    }
    
    struct DrawResult: Equatable {
        let id = UUID()
        let itemName: String
        let damagoType: DamagoType
    }
    
    @Published private(set) var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    static let drawCost = 100
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
        guard state.coinAmount >= StoreViewModel.drawCost else {
            state.error = Pulse("코인이 부족해요!")
            return
        }
        
        let availableDamagos = DamagoType.allCases.filter { !state.ownedDamagos.keys.contains($0) }
        guard let randomDamago = availableDamagos.randomElement() else {
            state.error = Pulse("모든 친구를 만났어요!")
            return
        }
        
        state.isLoading = true
        
        Task {
            do {
                try await createDamagoUseCase.execute(damagoType: randomDamago)
                // 성공 시 애니메이션 트리거
                state.drawResult = DrawResult(itemName: "새로운 친구", damagoType: randomDamago)
            } catch {
                state.error = Pulse("친구를 데려오는데 실패했어요.")
            }
            state.isLoading = false
        }
    }
}
