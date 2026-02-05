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
        var route: Pulse<Route>?
    }

    enum Route {
        case alert(errorMessage: String)
        case connection(opponentCode: String?)
        case tabBar
    }

    @Published private var state = State()

    private var cancellables = Set<AnyCancellable>()

    private let signInUseCase: SignInUseCase
    private let checkConnectionUseCase: CheckConnectionUseCase
    private let opponentCode: String?

    init(
        signInUseCase: SignInUseCase,
        checkConnectionUseCase: CheckConnectionUseCase,
        opponentCode: String? = nil
    ) {
        self.signInUseCase = signInUseCase
        self.checkConnectionUseCase = checkConnectionUseCase
        self.opponentCode = opponentCode
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
                state.route = nil
            }
            .store(in: &cancellables)

        return $state.eraseToAnyPublisher()
    }

    func signIn() async {
        do {
            try await signInUseCase.signIn()
            let isConnected = try await checkConnectionUseCase.execute()
            if isConnected {
                self.state.route = .init(.tabBar)
            } else {
                self.state.route = .init(.connection(opponentCode: opponentCode))
            }
        } catch {
            self.state.route = .init(.alert(errorMessage: error.userFriendlyMessage))
        }
    }
}
