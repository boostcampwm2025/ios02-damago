//
//  DamagoRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import Combine
import DamagoNetwork

final class DamagoRepository: DamagoRepositoryProtocol {
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
        return try await networkProvider.requestSuccess(DamagoAPI.feed(accessToken: token, damagoID: damagoID))
    }

    func observeDamagoSnapshot(damagoID: String) -> AnyPublisher<Result<DamagoSnapshotDTO, Error>, Never> {
        firestoreService.observe(collection: "damagos", document: damagoID)
    }

    func observeOwnedDamagos(coupleID: String) -> AnyPublisher<Result<[DamagoSnapshotDTO], Error>, Never> {
        firestoreService.observeQuery(collection: "damagos", field: "coupleID", value: coupleID)
    }
}
