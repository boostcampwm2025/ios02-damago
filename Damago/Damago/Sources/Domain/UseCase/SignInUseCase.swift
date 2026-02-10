//
//  SignInUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

protocol SignInUseCase {
    func execute() async throws
}

final class SignInUseCaseImpl: SignInUseCase {
    private let repository: UserRepositoryProtocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.signIn()
        try await repository.updateFCMToken(fcmToken: nil)
    }
}
