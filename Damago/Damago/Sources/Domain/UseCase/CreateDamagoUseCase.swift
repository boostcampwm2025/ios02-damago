//
//  CreateDamagoUseCase.swift
//  Damago
//
//  Created by 김재영 on 2/3/26.
//

import Foundation

protocol CreateDamagoUseCase {
    func execute() async throws -> DrawResult
}

final class CreateDamagoUseCaseImpl: CreateDamagoUseCase {
    private let repository: DamagoRepositoryProtocol
    
    init(damagoRepository: DamagoRepositoryProtocol) {
        self.repository = damagoRepository
    }
    
    func execute() async throws -> DrawResult {
        try await repository.create()
    }
}
