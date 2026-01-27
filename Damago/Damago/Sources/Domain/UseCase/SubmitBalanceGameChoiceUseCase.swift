//
//  SubmitBalanceGameChoiceUseCase.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

protocol SubmitBalanceGameChoiceUseCase {
    @discardableResult
    func execute(gameID: String, choice: Int) async throws -> Bool
}

final class SubmitBalanceGameChoiceUseCaseImpl: SubmitBalanceGameChoiceUseCase {
    private let repository: BalanceGameRepositoryProtocol
    
    init(repository: BalanceGameRepositoryProtocol) {
        self.repository = repository
    }
    
    @discardableResult
    func execute(gameID: String, choice: Int) async throws -> Bool {
        try await repository.submitChoice(gameID: gameID, choice: choice)
    }
}
