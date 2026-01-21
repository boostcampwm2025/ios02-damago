//
//  PetRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import Combine
import DamagoNetwork

final class PetRepository: PetRepositoryProtocol {
    private let networkProvider: NetworkProvider
    private let tokenProvider: TokenProvider
    private let firestoreService: FirestoreService

    init(
        networkProvider: NetworkProvider,
        tokenProvider: TokenProvider,
        firestoreService: FirestoreService
    ) {
        self.networkProvider = networkProvider
        self.tokenProvider = tokenProvider
        self.firestoreService = firestoreService
    }
    
    func feed(damagoID: String) async throws -> Bool {
        let token = try await tokenProvider.idToken()
        return try await networkProvider.requestSuccess(PetAPI.feed(accessToken: token, damagoID: damagoID))
    }

    func observePetSnapshot(damagoID: String) -> AnyPublisher<Result<PetSnapshotDTO, Error>, Never> {
        firestoreService.observe(collection: "damagos", document: damagoID)
    }
}
