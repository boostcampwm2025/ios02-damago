//
//  FetchCodeUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/15/26.
//

protocol FetchCodeUseCase {
    func execute() async throws -> (myCode: String, partnerCode: String?)
}

final class FetchCodeUseCaseImpl: FetchCodeUseCase {
    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute() async throws -> (myCode: String, partnerCode: String?) {
        try await userRepository.generateCode()
    }
}
