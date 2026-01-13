//
//  UseCaseAssembly.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

final class UseCaseAssembly: Assembly {
    func assemble(_ container: any DIContainer) {
        container.register(SignInUseCase.self) {
            SignInUseCaseImpl(repository: container.resolve(UserRepositoryProtocol.self))
        }
    }
}
