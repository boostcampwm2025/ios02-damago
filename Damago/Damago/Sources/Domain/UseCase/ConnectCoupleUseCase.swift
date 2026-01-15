//
//  ConnectCoupleUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/15/26.
//

protocol ConnectCoupleUseCase {
    func execute(code: String) async throws
}

final class ConnectCoupleUseCaseImpl: ConnectCoupleUseCase {
    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(code: String) async throws {
        try await userRepository.connectCouple(targetCode: code)
    }
}
