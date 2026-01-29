//
//  FetchBalanceGameUseCase.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

protocol FetchBalanceGameUseCase {
    func execute() -> AsyncStream<BalanceGameUIModel>
}

final class FetchBalanceGameUseCaseImpl: FetchBalanceGameUseCase {
    private let repository: BalanceGameRepositoryProtocol
    
    init(repository: BalanceGameRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() -> AsyncStream<BalanceGameUIModel> {
        AsyncStream { continuation in
            Task {
                for await dto in repository.fetchBalanceGame() {
                    continuation.yield(dto.toDomain())
                }
                continuation.finish()
            }
        }
    }
}
