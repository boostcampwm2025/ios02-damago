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

        var isFeedButtonEnabled: Bool { foodAmount > 0 }
        var isPokeButtonEnabled: Bool { true }
    }

    private var cancellables = Set<AnyCancellable>()
    @Published private var state = State()

    func transform(_ input: Input) -> AnyPublisher<State, Never> {
        input.viewDidLoad
            .receive(on: DispatchQueue.main)
            .sink { }
            .store(in: &cancellables)

        input.feedButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { }
            .store(in: &cancellables)

        input.pokeButtonDidTap
            .sink { }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }
}
