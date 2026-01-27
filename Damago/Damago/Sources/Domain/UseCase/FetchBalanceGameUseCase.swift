//
//  FetchBalanceGameUseCase.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

protocol FetchBalanceGameUseCase {
    func execute() async throws -> BalanceGameUIModel
}

final class FetchBalanceGameUseCaseImpl: FetchBalanceGameUseCase {
    private let repository: BalanceGameRepositoryProtocol
    
    init(repository: BalanceGameRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() async throws -> BalanceGameUIModel {
        let dto = try await repository.fetchBalanceGame()
        return dto.toDomain()
    }
}
