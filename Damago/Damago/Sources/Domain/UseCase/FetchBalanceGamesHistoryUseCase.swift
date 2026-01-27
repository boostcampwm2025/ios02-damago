//
//  FetchBalanceGamesHistoryUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

protocol FetchBalanceGamesHistoryUseCase {
    func execute(limit: Int) async throws -> [BalanceGameHistory]
}

final class FetchBalanceGamesHistoryUseCaseImpl: FetchBalanceGamesHistoryUseCase {
    private let repository: HistoryRepositoryProtocol

    init(repository: HistoryRepositoryProtocol) {
        self.repository = repository
    }

    func execute(limit: Int) async throws -> [BalanceGameHistory] {
        try await repository.fetchBalanceGameHistory(limit: limit)
    }
}
