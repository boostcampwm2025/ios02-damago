//
//  SaveLiveActivityTokenUseCase.swift
//  Damago
//
//  Created by 박현수 on 2/3/26.
//

import Foundation

protocol SaveLiveActivityTokenUseCase {
    func execute(startToken: String?, updateToken: String?) async throws -> Bool
}

final class SaveLiveActivityTokenUseCaseImpl: SaveLiveActivityTokenUseCase {
    private let repository: PushRepositoryProtocol

    init(repository: PushRepositoryProtocol) {
        self.repository = repository
    }

    func execute(startToken: String?, updateToken: String?) async throws -> Bool {
        try await repository.saveLiveActivityToken(startToken: startToken, updateToken: updateToken)
    }
}
