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

    func create() async throws -> DrawResult {
        let token = try await tokenProvider.idToken()
        let response: CreateDamagoResponse = try await networkProvider.request(
            DamagoAPI.create(accessToken: token)
        )
        guard let type = DamagoType(rawValue: response.damagoType) else {
            throw NetworkError.invalidResponse
        }
        return DrawResult(damagoType: type, isNew: response.isNew)
    }

    func observeDamagoSnapshot(damagoID: String) -> AnyPublisher<Result<DamagoSnapshotDTO, Error>, Never> {
        let firestorePath = FirestorePath.damagos(damagoID: damagoID)
        
        let publisher: AnyPublisher<Result<DamagoSnapshotDTO, Error>, Never> =
        firestoreService.observe(collection: firestorePath.collection, document: firestorePath.document)
        
        return publisher
    }

    func observeOwnedDamagos(coupleID: String) -> AnyPublisher<Result<[DamagoSnapshotDTO], Error>, Never> {
        let firestorePath = FirestorePath.ownedDamagos(coupleID: coupleID)
        
        guard let queryInfo = firestorePath.queryInfo else {
            return Just(.failure(NSError(domain: "InvalidPath", code: -1))).eraseToAnyPublisher()
        }
        
        let publisher: AnyPublisher<Result<[DamagoSnapshotDTO], Error>, Never> =
        firestoreService.observeQuery(collection: firestorePath.collection, field: queryInfo.field, value: queryInfo.value)
        
        return publisher
    }
}
