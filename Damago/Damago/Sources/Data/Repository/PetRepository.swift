//
//  PetRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import DamagoNetwork

final class PetRepository: PetRepositoryProtocol {
    private let networkProvider: NetworkProvider
    private let tokenProvider: TokenProvider

    init(networkProvider: NetworkProvider, tokenProvider: TokenProvider) {
        self.networkProvider = networkProvider
        self.tokenProvider = tokenProvider
    }
    
    func feed(damagoID: String) async throws -> Bool {
        let token = try await tokenProvider.idToken()
        return try await networkProvider.requestSuccess(PetAPI.feed(accessToken: token, damagoID: damagoID))
    }
}
