//
//  DamagoRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

import Combine

protocol DamagoRepositoryProtocol {
    func feed(damagoID: String) async throws -> Bool
    func create(damagoType: DamagoType) async throws -> Bool
    func observeDamagoSnapshot(damagoID: String) -> AnyPublisher<Result<DamagoSnapshotDTO, Error>, Never>
    func observeOwnedDamagos(coupleID: String) -> AnyPublisher<Result<[DamagoSnapshotDTO], Error>, Never>
}
