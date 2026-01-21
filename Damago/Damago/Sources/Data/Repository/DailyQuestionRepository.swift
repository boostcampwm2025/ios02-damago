//
//  DailyQuestionRepository.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

import Combine
import DamagoNetwork
import OSLog

final class DailyQuestionRepository: DailyQuestionRepositoryProtocol {
    private let networkProvider: NetworkProvider
    private let tokenProvider: TokenProvider
    private let firestoreService: FirestoreService
    
    init(
        networkProvider: NetworkProvider,
        tokenProvider: TokenProvider,
        firestoreService: FirestoreService
    ) {
        self.networkProvider = networkProvider
        self.tokenProvider = tokenProvider
        self.firestoreService = firestoreService
    }
    
    func fetchDailyQuestion() async throws -> DailyQuestionDTO {
        let token = try await tokenProvider.idToken()
        return try await networkProvider.request(DailyQuestionAPI.fetch(accessToken: token))
    }
    
    func submitAnswer(questionID: String, answer: String) async throws -> Bool {
        let token = try await tokenProvider.idToken()
        return try await networkProvider.requestSuccess(
            DailyQuestionAPI.submit(
                accessToken: token,
                questionID: questionID,
                answer: answer
            )
        )
    }
    
    func observeAnswer(
        coupleID: String,
        questionID: String,
        questionContent: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<DailyQuestionDTO, Error>, Never> {
        firestoreService.observe(
            collection: "couples/\(coupleID)/dailyQuestionAnswers",
            document: questionID
        )
        .map { (result: Result<FirestoreAnswerDTO, Error>) in
            switch result {
            case .success(let dto):
                let combinedDTO = DailyQuestionDTO(
                    questionID: questionID,
                    questionContent: questionContent,
                    user1Answer: dto.user1Answer,
                    user2Answer: dto.user2Answer,
                    isUser1: isUser1
                )
                return .success(combinedDTO)

            case .failure(let error):
                SharedLogger.interaction.error("답변 조회 실패: \(error.localizedDescription)")
                return .failure(error)
            }
        }
        .eraseToAnyPublisher()
    }
}

private struct FirestoreAnswerDTO: Decodable {
    let user1Answer: String?
    let user2Answer: String?
    let bothAnswered: Bool?
}
