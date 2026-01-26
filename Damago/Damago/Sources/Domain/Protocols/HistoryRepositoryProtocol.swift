//
//  HistoryRepositoryProtocol.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

protocol HistoryRepositoryProtocol {
    func fetchDailyQuestionHistory(limit: Int) async throws -> [DailyQuestionHistory]
    func fetchBalanceGameHistory(limit: Int) async throws -> [BalanceGameHistory]
}
