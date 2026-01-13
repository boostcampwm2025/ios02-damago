//
//  PushRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import DamagoNetwork

final class PushRepository: PushRepositoryProtocol {
    private let networkProvider: NetworkProvider
    
    init(networkProvider: NetworkProvider) {
        self.networkProvider = networkProvider
    }
    
    func poke(udid: String) async throws -> Bool {
        try await networkProvider.requestSuccess(PushAPI.poke(udid: udid))
    }
    
    func saveLiveActivityToken(udid: String, startToken: String?, updateToken: String?) async throws -> Bool {
        try await networkProvider.requestSuccess(
            PushAPI.saveLiveActivityToken(
                udid: udid,
                laStartToken: startToken,
                laUpdateToken: updateToken
            )
        )
    }
}
