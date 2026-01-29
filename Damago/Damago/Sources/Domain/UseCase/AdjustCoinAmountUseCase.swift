//
//  AdjustCoinAmountUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/28/26.
//

import Foundation

protocol AdjustCoinAmountUseCase {
    @discardableResult
    func execute(amount: Int) async throws -> Int
}

final class AdjustCoinAmountUseCaseImpl: AdjustCoinAmountUseCase {
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    @discardableResult
    func execute(amount: Int) async throws -> Int {
        try await userRepository.adjustCoin(amount: amount)
    }
}
