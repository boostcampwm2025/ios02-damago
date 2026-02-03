//
//  FeedDamagoUseCase.swift
//  Damago
//
//  Created by 박현수 on 2/3/26.
//

import Foundation

protocol FeedDamagoUseCase {
    func execute(damagoID: String) async throws -> Bool
}

final class FeedDamagoUseCaseImpl: FeedDamagoUseCase {
    private let repository: DamagoRepositoryProtocol

    init(repository: DamagoRepositoryProtocol) {
        self.repository = repository
    }

    func execute(damagoID: String) async throws -> Bool {
        try await repository.feed(damagoID: damagoID)
    }
}
