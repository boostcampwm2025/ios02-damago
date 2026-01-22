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
    private let localDataSource: DailyQuestionLocalDataSourceProtocol
    
    init(
        networkProvider: NetworkProvider,
        tokenProvider: TokenProvider,
        firestoreService: FirestoreService,
        localDataSource: DailyQuestionLocalDataSourceProtocol
    ) {
        self.networkProvider = networkProvider
        self.tokenProvider = tokenProvider
        self.firestoreService = firestoreService
        self.localDataSource = localDataSource
    }
    
    func fetchDailyQuestion() async throws -> DailyQuestionDTO {
        let token = try await tokenProvider.idToken()
        do {
            let dto: DailyQuestionDTO = try await networkProvider.request(DailyQuestionAPI.fetch(accessToken: token))
            await saveToLocalAnswer(dto: dto)
            return dto
        } catch {
            SharedLogger.interaction.error("API 조회 실패 로컬 캐시 조회: \(error.localizedDescription)")
            
            // Fallback: 로컬 캐시 조회
            if let entity = try? await localDataSource.fetchLatestQuestion() {
                return DailyQuestionDTO(
                    questionID: entity.questionID,
                    questionContent: entity.questionContent,
                    user1Answer: entity.user1Answer,
                    user2Answer: entity.user2Answer,
                    isUser1: entity.isUser1
                )
            }
            throw error
        }
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
        .handleEvents(receiveOutput: { [weak self] result in
            if case .success(let response) = result {
                Task {
                    await self?.updateLocalAnswer(
                        questionID: questionID,
                        response: response
                    )
                }
            }
        })
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
    
    @MainActor
    private func saveToLocalAnswer(dto: DailyQuestionDTO) async {
        do {
            let entity = DailyQuestionEntity(
                questionID: dto.questionID,
                questionContent: dto.questionContent,
                user1Answer: dto.user1Answer,
                user2Answer: dto.user2Answer,
                isUser1: dto.isUser1
            )
            try await localDataSource.saveQuestion(entity)
        } catch {
            SharedLogger.interaction.error("Local save failed: \(error)")
        }
    }
    
    @MainActor
    private func updateLocalAnswer(questionID: String, response: FirestoreAnswerDTO) async {
        do {
            try await localDataSource.updateAnswer(
                questionID: questionID,
                user1Answer: response.user1Answer,
                user2Answer: response.user2Answer
            )
        } catch {
            SharedLogger.interaction.error("Local update failed: \(error)")
        }
    }
}

private struct FirestoreAnswerDTO: Decodable {
    let user1Answer: String?
    let user2Answer: String?
    let bothAnswered: Bool?
}
