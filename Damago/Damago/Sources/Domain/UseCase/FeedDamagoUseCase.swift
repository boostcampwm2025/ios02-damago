//
//  FeedDamagoUseCase.swift
//  Damago
//
//  Created by 박현수 on 2/3/26.
//

import Foundation

protocol FeedDamagoUseCase {
    func execute(damagoID: String) async throws
}

final class FeedDamagoUseCaseImpl: FeedDamagoUseCase {
    private let repository: DamagoRepositoryProtocol

    init(repository: DamagoRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(damagoID: String) async throws {
        let latestStatus = try await repository.feed(damagoID: damagoID)
        
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
