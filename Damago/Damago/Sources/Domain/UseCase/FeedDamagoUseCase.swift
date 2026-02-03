//
//  FeedDamagoUseCase.swift
//  Damago
//
//  Created by 김재영 on 2/3/26.
//

import Foundation

protocol FeedDamagoUseCase {
    func execute(damagoID: String) async throws
}

final class FeedDamagoUseCaseImpl: FeedDamagoUseCase {
    private let damagoRepository: DamagoRepositoryProtocol
    
    init(damagoRepository: DamagoRepositoryProtocol) {
        self.damagoRepository = damagoRepository
    }
    
    func execute(damagoID: String) async throws {
        let latestStatus = try await damagoRepository.feed(damagoID: damagoID)
        
        LiveActivityManager.shared.updateActivity(with: latestStatus)
    }
}
