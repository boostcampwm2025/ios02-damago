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
    
    func fetchDailyQuestion() -> AsyncStream<DailyQuestionDTO> {
        AsyncStream { continuation in
            Task {
                // 1. 로컬 데이터 조회 및 즉시 방출 (오늘 데이터인 경우만)
                if let entity = try? await localDataSource.fetchLatestQuestion(),
                   let lastUpdated = entity.lastUpdated,
                   Calendar.current.isDateInToday(lastUpdated) {
                    
                    let dto = DailyQuestionDTO(
                        questionID: entity.questionID,
                        questionContent: entity.questionContent,
                        user1Answer: entity.user1Answer,
                        user2Answer: entity.user2Answer,
                        bothAnswered: entity.bothAnswered,
                        lastAnsweredAt: entity.lastAnsweredAt,
                        isUser1: entity.isUser1
                    )
                    continuation.yield(dto)
                }

                // 2. 네트워크 데이터 조회 및 방출
                do {
                    let token = try await tokenProvider.idToken()
                    let dto: DailyQuestionDTO = try await networkProvider.request(
                        DailyQuestionAPI.fetch(accessToken: token)
                    )
                    await saveToLocalAnswer(dto: dto)
                    continuation.yield(dto)
                } catch {
                    SharedLogger.interaction.error("Daily Question 네트워크 조회 실패: \(error.localizedDescription)")
                }

                continuation.finish()
            }
        }
    }
    
    func submitAnswer(questionID: String, answer: String, isUser1: Bool) async throws -> Bool {
        let previousEntity = try await localDataSource.fetchQuestion(id: questionID)
        let previousUser1Answer = previousEntity?.user1Answer
        let previousUser2Answer = previousEntity?.user2Answer
        let previousBothAnswered = previousEntity?.bothAnswered ?? false
        let previousLastAnsweredAt = previousEntity?.lastAnsweredAt
        
        // 로컬 업데이트 수행
        try await localDataSource.updateAnswer(
            questionID: questionID,
            user1Answer: isUser1 ? answer : previousUser1Answer,
            user2Answer: isUser1 ? previousUser2Answer : answer,
            bothAnswered: previousBothAnswered,
            lastAnsweredAt: Date()
        )
        
        do {
            let token = try await tokenProvider.idToken()
            let success = try await networkProvider.requestSuccess(
                DailyQuestionAPI.submit(
                    accessToken: token,
                    questionID: questionID,
                    answer: answer
                )
            )
            return success
        } catch {
            SharedLogger.interaction.error("API 제출 실패, 로컬 데이터 롤백: \(error.localizedDescription)")
            
            // 실패 시 롤백: 이전 상태로 복구
            try await localDataSource.updateAnswer(
                questionID: questionID,
                user1Answer: previousUser1Answer,
                user2Answer: previousUser2Answer,
                bothAnswered: previousBothAnswered,
                lastAnsweredAt: previousLastAnsweredAt
            )
            throw error
        }
    }

    // swiftlint:disable trailing_closure
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
                    bothAnswered: dto.bothAnswered,
                    lastAnsweredAt: dto.lastAnsweredAt,
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
    // swiftlint:enable trailing_closure

    @MainActor
    private func saveToLocalAnswer(dto: DailyQuestionDTO) async {
        do {
            let entity = DailyQuestionEntity(
                questionID: dto.questionID,
                questionContent: dto.questionContent,
                user1Answer: dto.user1Answer,
                user2Answer: dto.user2Answer,
                bothAnswered: dto.bothAnswered ?? false,
                lastAnsweredAt: dto.lastAnsweredAt,
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
                user2Answer: response.user2Answer,
                bothAnswered: response.bothAnswered ?? false,
                lastAnsweredAt: response.lastAnsweredAt
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
    let lastAnsweredAt: Date?
}
