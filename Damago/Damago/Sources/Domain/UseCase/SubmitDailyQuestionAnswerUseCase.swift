//
//  SubmitDailyQuestionAnswerUseCase.swift
//  Damago
//
//  Created by 김재영 on 1/21/26.
//

protocol SubmitDailyQuestionAnswerUseCase {
    @discardableResult
    func execute(questionID: String, answer: String) async throws -> Bool
}

final class SubmitDailyQuestionAnswerUseCaseImpl: SubmitDailyQuestionAnswerUseCase {
    private let dailyQuestionRepository: DailyQuestionRepositoryProtocol
    
    init(dailyQuestionRepository: DailyQuestionRepositoryProtocol) {
        self.dailyQuestionRepository = dailyQuestionRepository
    }
    
    @discardableResult
    func execute(questionID: String, answer: String) async throws -> Bool {
        try await dailyQuestionRepository.submitAnswer(questionID: questionID, answer: answer)
    }
}
