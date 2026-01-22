//
//  PetRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

import Combine

protocol PetRepositoryProtocol {
    func feed(damagoID: String) async throws -> Bool
    func observePetSnapshot(damagoID: String) -> AnyPublisher<Result<PetSnapshotDTO, Error>, Never>
}
