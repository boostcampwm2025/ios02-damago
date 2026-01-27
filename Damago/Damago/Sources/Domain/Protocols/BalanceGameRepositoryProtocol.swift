//
//  BalanceGameRepositoryProtocol.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

import Combine

protocol BalanceGameRepositoryProtocol {
    func fetchBalanceGame() async throws -> BalanceGameDTO
    func submitChoice(gameID: String, choice: Int) async throws -> Bool
    func observeAnswer(
        coupleID: String,
        gameID: String,
        questionContent: String,
        option1: String,
        option2: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<BalanceGameDTO, Error>, Never>
}
