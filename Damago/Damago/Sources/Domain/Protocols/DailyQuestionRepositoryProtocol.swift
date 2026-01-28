//
//  DailyQuestionRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

import Combine

protocol DailyQuestionRepositoryProtocol {
    func fetchDailyQuestion() -> AsyncStream<DailyQuestionDTO>
    func submitAnswer(questionID: String, answer: String, isUser1: Bool) async throws -> Bool
    func observeAnswer(
        coupleID: String,
        questionID: String,
        questionContent: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<DailyQuestionDTO, Error>, Never>
}
