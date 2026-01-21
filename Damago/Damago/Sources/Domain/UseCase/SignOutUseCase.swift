//
//  SignOutUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

protocol SignOutUseCase {
    func execute() throws
}

final class SignOutUseCaseImpl: SignOutUseCase {
    private let repository: UserRepositoryProtocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute() throws {
        try repository.signOut()
    }
}
