//
//  HistoryRepository.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import Foundation
import DamagoNetwork

final class HistoryRepository: HistoryRepositoryProtocol {
    private let networkProvider: NetworkProvider
    private let tokenProvider: TokenProvider
    
    init(networkProvider: NetworkProvider, tokenProvider: TokenProvider) {
        self.networkProvider = networkProvider
        self.tokenProvider = tokenProvider
    }
    
    func fetchDailyQuestionHistory(limit: Int) async throws -> [DailyQuestionHistory] {
        let token = try await tokenProvider.idToken()
        let dtos: [DailyQuestionHistoryDTO] = try await networkProvider.request(
            HistoryAPI.fetchDailyQuestionHistory(accessToken: token, limit: limit)
        )
        return dtos.map { $0.toDomain() }
    }
    
    func fetchBalanceGameHistory(limit: Int) async throws -> [BalanceGameHistory] {
        let token = try await tokenProvider.idToken()
        let dtos: [BalanceGameHistoryDTO] = try await networkProvider.request(
            HistoryAPI.fetchBalanceGameHistory(accessToken: token, limit: limit)
        )
        return dtos.map { $0.toDomain() }
    }
}
