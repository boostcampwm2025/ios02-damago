//
//  SubmitDailyQuestionAnswerUseCase.swift
//  Damago
//
//  Created by 김재영 on 1/21/26.
//

protocol SubmitDailyQuestionAnswerUseCase {
    @discardableResult
    func execute(questionID: String, answer: String, isUser1: Bool) async throws -> Bool
}

final class SubmitDailyQuestionAnswerUseCaseImpl: SubmitDailyQuestionAnswerUseCase {
    private let dailyQuestionRepository: DailyQuestionRepositoryProtocol
    
    init(dailyQuestionRepository: DailyQuestionRepositoryProtocol) {
        self.dailyQuestionRepository = dailyQuestionRepository
    }
    
    @discardableResult
    func execute(questionID: String, answer: String, isUser1: Bool) async throws -> Bool {
        try await dailyQuestionRepository.submitAnswer(questionID: questionID, answer: answer, isUser1: isUser1)
    }
}