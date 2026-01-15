//
//  PushRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import DamagoNetwork

final class PushRepository: PushRepositoryProtocol {
    private let networkProvider: NetworkProvider
    private let tokenProvider: TokenProvider

    init(networkProvider: NetworkProvider, tokenProvider: TokenProvider) {
        self.networkProvider = networkProvider
        self.tokenProvider = tokenProvider
    }

    func poke(message: String) async throws -> Bool {
        let token = try await tokenProvider.provide()
        return try await networkProvider.requestSuccess(PushAPI.poke(accessToken: token, message: message))
    }
    
    func saveLiveActivityToken(startToken: String?, updateToken: String?) async throws -> Bool {
        let token = try await tokenProvider.provide()
        return try await networkProvider.requestSuccess(
            PushAPI.saveLiveActivityToken(
                accessToken: token,
                laStartToken: startToken,
                laUpdateToken: updateToken
            )
        )
    }
}
