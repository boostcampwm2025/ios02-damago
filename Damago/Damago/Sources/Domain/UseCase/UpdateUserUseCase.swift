//
//  UpdateUserUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Foundation

protocol UpdateUserUseCase {
    func execute(nickname: String?, anniversaryDate: Date?) async throws
}

final class UpdateUserUseCaseImpl: UpdateUserUseCase {
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    func execute(nickname: String?, anniversaryDate: Date?) async throws {
        try await userRepository.updateUserInfo(
            nickname: nickname,
            anniversaryDate: anniversaryDate
        )
    }
}
