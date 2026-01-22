//
//  UpdateFCMTokenUseCase.swift
//  Damago
//
//  Created by 김재영 on 1/22/26.
//

import Foundation

protocol UpdateFCMTokenUseCase {
    func execute(fcmToken: String) async throws
}

final class UpdateFCMTokenUseCaseImpl: UpdateFCMTokenUseCase {
    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(fcmToken: String) async throws {
        try await userRepository.updateFCMToken(fcmToken: fcmToken)
    }
}
