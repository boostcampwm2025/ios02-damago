//
//  FetchDailyQuestionUseCase.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

import Combine

protocol FetchDailyQuestionUseCase {
    func execute() -> AnyPublisher<DailyQuestionUIModel, Error>
}

final class FetchDailyQuestionUseCaseImpl: FetchDailyQuestionUseCase {
    private let dailyQuestionRepository: DailyQuestionRepositoryProtocol
    
    init(dailyQuestionRepository: DailyQuestionRepositoryProtocol) {
        self.dailyQuestionRepository = dailyQuestionRepository
    }
    
    func execute() -> AnyPublisher<DailyQuestionUIModel, Error> {
        dailyQuestionRepository.fetchDailyQuestion()
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }
}