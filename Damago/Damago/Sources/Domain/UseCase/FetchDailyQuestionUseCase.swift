//
//  FetchDailyQuestionUseCase.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

protocol FetchDailyQuestionUseCase {
    func execute() -> AsyncStream<DailyQuestionUIModel>
}

final class FetchDailyQuestionUseCaseImpl: FetchDailyQuestionUseCase {
    private let dailyQuestionRepository: DailyQuestionRepositoryProtocol
    
    init(dailyQuestionRepository: DailyQuestionRepositoryProtocol) {
        self.dailyQuestionRepository = dailyQuestionRepository
    }
    
    func execute() -> AsyncStream<DailyQuestionUIModel> {
        AsyncStream { continuation in
            Task {
                for await dto in dailyQuestionRepository.fetchDailyQuestion() {
                    continuation.yield(dto.toDomain())
                }
                continuation.finish()
            }
        }
    }
}
