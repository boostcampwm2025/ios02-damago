//
//  InteractionViewModel.swift
//  Damago
//
//  Created by 김재영 on 1/15/26.
//

import Combine
import Foundation

final class InteractionViewModel: ViewModel {
    let title = "커플 활동"
    let subtitle = "더 가까워지기 위한 일상 활동"
    
    struct Input {
        let historyButtonDidTap: AnyPublisher<Void, Never>
    }
    
    struct State {
        
    }
    
    @Published private var state = State()
    private var cancellables = Set<AnyCancellable>()
    
    init() { }
    
    func transform(_ input: Input) -> Output {
        input.historyButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleHistoryButtonTap()
            }
            .store(in: &cancellables)
        
        return $state.eraseToAnyPublisher()
    }
    
    func handleHistoryButtonTap() {
        print("지난 활동 확인하기 버튼 클릭")
    }
}
