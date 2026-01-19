//
//  ObservePetStatusUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/19/26.
//

import Combine

protocol ObservePetStatusUseCase {
    func execute(damagoID: String) -> AnyPublisher<Result<PetStatus, Error>, Never>
}

final class ObservePetStatusUseCaseImpl: ObservePetStatusUseCase {
    private let petRepository: PetRepositoryProtocol
    
    init(petRepository: PetRepositoryProtocol) {
        self.petRepository = petRepository
    }
    
    func execute(damagoID: String) -> AnyPublisher<Result<PetStatus, Error>, Never> {
        return petRepository.observePetStatus(damagoID: damagoID)
    }
}
