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
        let alertButtonDidTap: AnyPublisher<Void, Never>
    }

    struct State {
        var errorMessage: Pulse<String>?
    }

    @Published private var state = State()

    private var cancellables = Set<AnyCancellable>()

    private let signInUseCase: SignInUseCase

    init(signInUseCase: SignInUseCase) {
        self.signInUseCase = signInUseCase
    }

    func transform(_ input: Input) -> Output {
        input.signInButtonDidTap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { await self.signIn() }
            }
            .store(in: &cancellables)

        input.alertButtonDidTap
            .sink { [weak self] in
                guard let self else { return }
                state.errorMessage = nil
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    func signIn() async {
        do {
            try await signInUseCase.signIn()
        } catch {
            self.state.errorMessage = .init(error.localizedDescription)
        }
    }
}
