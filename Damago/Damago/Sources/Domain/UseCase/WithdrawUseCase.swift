//
//  WithdrawUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/22/26.
//

protocol WithdrawUseCase {
    func execute() async throws
}

final class WithdrawUseCaseImpl: WithdrawUseCase {
    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute() async throws {
        try await userRepository.withdraw()
    }
}
