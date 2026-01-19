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

    func observePetStatus(damagoID: String) -> AnyPublisher<Result<PetStatus, Error>, Never> {
        firestoreService.observe(collection: "damagos", document: damagoID)
            .map { (result: Result<DamagoDTO, Error>) in
                switch result {
                case let .success(value):
                    return .success(value.toDomain())
                case let .failure(error):
                    return .failure(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

