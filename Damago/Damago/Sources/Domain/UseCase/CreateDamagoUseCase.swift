//
//  CreateDamagoUseCase.swift
//  Damago
//
//  Created by Gemini on 2/3/26.
//

import Foundation

protocol CreateDamagoUseCase {
    func execute() async throws -> DamagoType
}

final class CreateDamagoUseCaseImpl: CreateDamagoUseCase {
    private let repository: DamagoRepositoryProtocol
    
    init(damagoRepository: DamagoRepositoryProtocol) {
        self.repository = damagoRepository
    }
    
    func execute() async throws -> DamagoType {
        try await repository.create()
    }
}
