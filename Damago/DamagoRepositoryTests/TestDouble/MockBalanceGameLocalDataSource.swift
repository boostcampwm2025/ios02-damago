//
//  MockBalanceGameLocalDataSource.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

import Foundation
import SwiftData
@testable import Damago

@MainActor
final class MockBalanceGameLocalDataSource: BalanceGameLocalDataSourceProtocol, @unchecked Sendable {
    var fetchGameResult: BalanceGameEntity?
    var fetchGameError: Error?
    
    var fetchLatestGameHandler: (() async throws -> BalanceGameEntity?)?
    var saveGameCalledWith: BalanceGameEntity?
    
    var updateChoiceCalledWith: (gameID: String, user1Choice: Int?, user2Choice: Int?, lastAnsweredAt: Date?)?
    var updateChoiceError: Error?
    
    func fetchGame(id: String) async throws -> BalanceGameEntity? {
        if let error = fetchGameError { throw error }
        return fetchGameResult
    }

    func fetchLatestGame() async throws -> BalanceGameEntity? {
        if let error = fetchGameError { throw error }
        return try await fetchLatestGameHandler?()
    }

    func saveGame(_ entity: BalanceGameEntity) async throws {
        saveGameCalledWith = entity
    }

    func updateChoice(
        gameID: String,
        user1Choice: Int?,
        user2Choice: Int?,
        lastAnsweredAt: Date?
    ) async throws {
        if let error = updateChoiceError { throw error }
        updateChoiceCalledWith = (gameID, user1Choice, user2Choice, lastAnsweredAt)
    }
}
