//
//  ObserveDamagoSnapshotUseCase.swift
//  Damago
//
//  Created by 박현수 on 2/3/26.
//

import Combine

protocol ObserveDamagoSnapshotUseCase {
    func execute(damagoID: String) -> AnyPublisher<Result<DamagoSnapshotDTO, Error>, Never>
}

final class ObserveDamagoSnapshotUseCaseImpl: ObserveDamagoSnapshotUseCase {
    private let repository: DamagoRepositoryProtocol

    init(repository: DamagoRepositoryProtocol) {
        self.repository = repository
    }

    func execute(damagoID: String) -> AnyPublisher<Result<DamagoSnapshotDTO, Error>, Never> {
        repository.observeDamagoSnapshot(damagoID: damagoID)
    }
}
