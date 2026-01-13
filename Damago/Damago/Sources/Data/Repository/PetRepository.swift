//
//  PetRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import DamagoNetwork

final class PetRepository: PetRepositoryProtocol {
    private let networkProvider: NetworkProvider
    
    init(networkProvider: NetworkProvider) {
        self.networkProvider = networkProvider
    }
    
    func feed(damagoID: String) async throws -> Bool {
        try await networkProvider.requestSuccess(PetAPI.feed(damagoID: damagoID))
    }
}
