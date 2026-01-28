//
//  BalanceGameLocalDataSource.swift
//  Damago
//
//  Created by Eden Landelyse on 1/28/26.
//

import Foundation
import SwiftData

@MainActor
protocol BalanceGameLocalDataSourceProtocol {
    func fetchGame(id: String) async throws -> BalanceGameEntity?
    func fetchLatestGame() async throws -> BalanceGameEntity?
    func saveGame(_ entity: BalanceGameEntity) async throws
    func updateChoice(
        gameID: String,
        user1Choice: Int?,
        user2Choice: Int?,
        lastAnsweredAt: Date?
    ) async throws
}

@MainActor
final class BalanceGameLocalDataSource: BalanceGameLocalDataSourceProtocol {
    private let storage: SwiftDataStorage

    init(storage: SwiftDataStorage) {
        self.storage = storage
    }

    func fetchGame(id: String) async throws -> BalanceGameEntity? {
        let descriptor = FetchDescriptor<BalanceGameEntity>(
            predicate: #Predicate { $0.gameID == id }
        )
        return try storage.context.fetch(descriptor).first
    }

    func fetchLatestGame() async throws -> BalanceGameEntity? {
        var descriptor = FetchDescriptor<BalanceGameEntity>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try storage.context.fetch(descriptor).first
    }

    func saveGame(_ entity: BalanceGameEntity) async throws {
        storage.context.insert(entity)
        try storage.context.save()
    }

    func updateChoice(
        gameID: String,
        user1Choice: Int?,
        user2Choice: Int?,
        lastAnsweredAt: Date?
    ) async throws {
        let descriptor = FetchDescriptor<BalanceGameEntity>(
            predicate: #Predicate { $0.gameID == gameID }
        )

        if let existingEntity = try storage.context.fetch(descriptor).first {
            existingEntity.user1Choice = user1Choice
            existingEntity.user2Choice = user2Choice
            existingEntity.lastAnsweredAt = lastAnsweredAt
            existingEntity.lastUpdated = Date()

            try storage.context.save()
        }
    }
}
