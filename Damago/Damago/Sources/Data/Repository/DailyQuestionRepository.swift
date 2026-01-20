//
//  DailyQuestionRepository.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

import DamagoNetwork

final class DailyQuestionRepository: DailyQuestionRepositoryProtocol {
    private let networkProvider: NetworkProvider
    private let tokenProvider: TokenProvider
    
    init(networkProvider: NetworkProvider, tokenProvider: TokenProvider) {
        self.networkProvider = networkProvider
        self.tokenProvider = tokenProvider
    }
    
    func fetchDailyQuestion() async throws -> DailyQuestionDTO {
        let token = try await tokenProvider.idToken()
        return try await networkProvider.request(DailyQuestionAPI.fetch(accessToken: token))
    }
}
