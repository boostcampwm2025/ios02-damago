//
//  FetchDailyQuestionUseCase.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

protocol FetchDailyQuestionUseCase {
    func execute() async throws -> DailyQuestionUIModel
}

final class FetchDailyQuestionUseCaseImpl: FetchDailyQuestionUseCase {
    private let dailyQuestionRepository: DailyQuestionRepositoryProtocol
    
    init(dailyQuestionRepository: DailyQuestionRepositoryProtocol) {
        self.dailyQuestionRepository = dailyQuestionRepository
    }
    
    func execute() async throws -> DailyQuestionUIModel {
        let dto = try await dailyQuestionRepository.fetchDailyQuestion()
        return dto.toDomain()
    }
}
