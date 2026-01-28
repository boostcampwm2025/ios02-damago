//
//  FetchUserInfoUseCase.swift
//  Damago
//
//  Created by loyH on 1/27/26.
//

import Foundation

protocol FetchUserInfoUseCase {
    func execute() async throws -> UserInfo
}

final class FetchUserInfoUseCaseImpl: FetchUserInfoUseCase {
    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute() async throws -> UserInfo {
        try await userRepository.getUserInfo()
    }
}
