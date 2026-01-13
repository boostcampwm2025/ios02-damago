//
//  SignInViewModel.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import Combine
import Foundation

final class SignInViewModel: ViewModel {
    struct Input {
        let signInButtonDidTap: AnyPublisher<Void, Never>
    }

    struct State { }

    @Published private var state = State()

    private var cancellables = Set<AnyCancellable>()

    func transform(_ input: Input) -> Output {
        input.signInButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }
}
