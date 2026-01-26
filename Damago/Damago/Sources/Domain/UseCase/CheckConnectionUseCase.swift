//
//  CheckConnectionUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/22/26.
//

protocol CheckConnectionUseCase {
    func execute() async throws -> Bool
}

final class CheckConnectionUseCaseImpl: CheckConnectionUseCase {
    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute() async throws -> Bool {
        try await userRepository.checkCoupleConnection()
    }
}
