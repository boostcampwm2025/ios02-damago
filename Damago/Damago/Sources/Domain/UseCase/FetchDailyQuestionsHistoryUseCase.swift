//
//  FetchDailyQuestionsHistoryUseCase.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import Foundation

protocol FetchDailyQuestionsHistoryUseCase {
    func execute(limit: Int) async throws -> [DailyQuestionHistory]
}

final class FetchDailyQuestionsHistoryUseCaseImpl: FetchDailyQuestionsHistoryUseCase {
    private let repository: HistoryRepositoryProtocol

    init(repository: HistoryRepositoryProtocol) {
        self.repository = repository
    }

    func execute(limit: Int) async throws -> [DailyQuestionHistory] {
        try await repository.fetchDailyQuestionHistory(limit: limit)
    }
}
