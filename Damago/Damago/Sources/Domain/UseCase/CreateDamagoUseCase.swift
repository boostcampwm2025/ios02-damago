//
//  CreateDamagoUseCase.swift
//  Damago
//
//  Created by Gemini on 2/3/26.
//

import Foundation

protocol CreateDamagoUseCase {
    func execute(damagoType: DamagoType) async throws
}

final class CreateDamagoUseCaseImpl: CreateDamagoUseCase {
    private let repository: DamagoRepositoryProtocol
    
    init(damagoRepository: DamagoRepositoryProtocol) {
        self.repository = damagoRepository
    }
    
    func execute(damagoType: DamagoType) async throws {
        _ = try await repository.create(damagoType: damagoType)
    }
}
