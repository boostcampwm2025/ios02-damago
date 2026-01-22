//
//  ObserveDailyQuestionAnswerUseCase.swift
//  Damago
//
//  Created by 김재영 on 1/21/26.
//

import Combine

protocol ObserveDailyQuestionAnswerUseCase {
    func execute(
        coupleID: String,
        questionID: String,
        questionContent: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<DailyQuestionUIModel, Error>, Never>
}

final class ObserveDailyQuestionAnswerUseCaseImpl: ObserveDailyQuestionAnswerUseCase {
    private let dailyQuestionRepository: DailyQuestionRepositoryProtocol
    
    init(dailyQuestionRepository: DailyQuestionRepositoryProtocol) {
        self.dailyQuestionRepository = dailyQuestionRepository
    }
    
    func execute(
        coupleID: String,
        questionID: String,
        questionContent: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<DailyQuestionUIModel, Error>, Never> {
        dailyQuestionRepository.observeAnswer(
            coupleID: coupleID,
            questionID: questionID,
            questionContent: questionContent,
            isUser1: isUser1
        )
        .map { result in
            switch result {
            case .success(let dto):
                return .success(dto.toDomain())
            case .failure(let error):
                return .failure(error)
            }
        }
        .eraseToAnyPublisher()
    }
}
