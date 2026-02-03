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
        var latestStatus = try await damagoRepository.feed(damagoID: damagoID)
        
        let updatedStatus = DamagoStatus(
            damagoName: latestStatus.damagoName,
            damagoType: latestStatus.damagoType,
            level: latestStatus.level,
            currentExp: latestStatus.currentExp,
            maxExp: latestStatus.maxExp,
            isHungry: latestStatus.isHungry,
            statusMessage: latestStatus.statusMessage,
            lastFedAt: Date(),
            totalPlayTime: latestStatus.totalPlayTime,
            lastActiveAt: latestStatus.lastActiveAt
        )
        
        LiveActivityManager.shared.updateActivity(with: updatedStatus)
    }
}
