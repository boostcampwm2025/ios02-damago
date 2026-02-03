//
//  DamagoRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import Combine
import DamagoNetwork
import Foundation

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
    
    func feed(damagoID: String) async throws -> DamagoStatus {
        let token = try await tokenProvider.idToken()
        let response: DamagoStatusResponse = try await networkProvider.request(
            DamagoAPI.feed(accessToken: token, damagoID: damagoID)
        )
        
        return DamagoStatus(
            damagoName: response.damagoName,
            damagoType: DamagoType(rawValue: response.damagoType) ?? .basicBlack,
            level: response.level,
            currentExp: response.currentExp,
            maxExp: response.maxExp,
            isHungry: response.isHungry,
            statusMessage: response.statusMessage,
            lastFedAt: response.lastFedAt,
            totalPlayTime: response.totalPlayTime ?? 0,
            lastActiveAt: response.lastActiveAt
        )
    }

    func observeDamagoSnapshot(damagoID: String) -> AnyPublisher<Result<DamagoSnapshotDTO, Error>, Never> {
        firestoreService.observe(collection: "damagos", document: damagoID)
    }

    func observeOwnedDamagos(coupleID: String) -> AnyPublisher<Result<[DamagoSnapshotDTO], Error>, Never> {
        firestoreService.observeQuery(collection: "damagos", field: "coupleID", value: coupleID)
    }
}
