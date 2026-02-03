//
//  PokeDamagoUseCase.swift
//  Damago
//
//  Created by 박현수 on 2/3/26.
//

import Foundation

protocol PokeDamagoUseCase {
    func execute(message: String) async throws -> Bool
}

final class PokeDamagoUseCaseImpl: PokeDamagoUseCase {
    private let repository: PushRepositoryProtocol

    init(repository: PushRepositoryProtocol) {
        self.repository = repository
    }

    func execute(message: String) async throws -> Bool {
        try await repository.poke(message: message)
    }
}
