//
//  DailyQuestionRepository.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

import Combine
import DamagoNetwork
import OSLog

final class DailyQuestionRepository: DailyQuestionRepositoryProtocol, DataSyncStrategy {
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
        createFetchStream(
            fetchLocal: { [weak self] in
                guard let self else { return nil }
                guard let entity = try await self.localDataSource.fetchLatestQuestion() else { return nil }
                return self.mapToDTO(entity: entity)
            },
            checkIsUpToDate: { dto in
                guard let lastAnswered = dto.lastAnsweredAt else { return false }
                return Calendar.current.isDateInToday(lastAnswered)
            },
            fetchNetwork: { [weak self] in
                guard let self else { throw URLError(.unknown) }
                let token = try await self.tokenProvider.idToken()
                return try await self.networkProvider.request(DailyQuestionAPI.fetch(accessToken: token))
            },
            saveToLocal: { [weak self] dto in
                await self?.saveToLocalAnswer(dto: dto)
            },
            onNetworkError: { error in
                SharedLogger.interaction.error("Daily Question 네트워크 조회 실패: \(error.localizedDescription)")
            }
        )
    }

    func submitAnswer(questionID: String, answer: String, isUser1: Bool) async throws -> Bool {
        let previousEntity = try await localDataSource.fetchQuestion(id: questionID)
        let previousUser1Answer = previousEntity?.user1Answer
        let previousUser2Answer = previousEntity?.user2Answer
        let previousBothAnswered = previousEntity?.bothAnswered ?? false
        let previousLastAnsweredAt = previousEntity?.lastAnsweredAt

        return try await submitWithOptimisticUpdate(
            backupState: previousEntity,
            updateLocal: { [weak self] in
                try await self?.localDataSource.updateAnswer(
                    questionID: questionID,
                    user1Answer: isUser1 ? answer : previousUser1Answer,
                    user2Answer: isUser1 ? previousUser2Answer : answer,
                    bothAnswered: previousBothAnswered,
                    lastAnsweredAt: Date()
                )
            },
            networkCall: { [weak self] in
                guard let self else { return false }
                let token = try await self.tokenProvider.idToken()
                return try await self.networkProvider.requestSuccess(
                    DailyQuestionAPI.submit(
                        accessToken: token,
                        questionID: questionID,
                        answer: answer
                    )
                )
            },
            rollbackLocal: { [weak self] _ in
                try await self?.localDataSource.updateAnswer(
                    questionID: questionID,
                    user1Answer: previousUser1Answer,
                    user2Answer: previousUser2Answer,
                    bothAnswered: previousBothAnswered,
                    lastAnsweredAt: previousLastAnsweredAt
                )
            },
            onFailure: { error in
                SharedLogger.interaction.error("API 제출 실패, 로컬 데이터 롤백: \(error.localizedDescription)")
            }
        )
    }

    func observeAnswer(
        coupleID: String,
        questionID: String,
        questionContent: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<DailyQuestionDTO, Error>, Never> {
        createObservePublisher(
            observe: {
                firestoreService.observe(
                    collection: "couples/\(coupleID)/dailyQuestionAnswers",
                    document: questionID
                )
            },
            updateLocal: { [weak self] response in
                await self?.updateLocalAnswer(
                    questionID: questionID,
                    response: response
                )
            },
            mapToResult: { response in
                DailyQuestionDTO(
                    questionID: questionID,
                    questionContent: questionContent,
                    user1Answer: response.user1Answer,
                    user2Answer: response.user2Answer,
                    bothAnswered: response.bothAnswered,
                    lastAnsweredAt: response.lastAnsweredAt,
                    isUser1: isUser1
                )
            }
        )
    }

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

    private func mapToDTO(entity: DailyQuestionEntity) -> DailyQuestionDTO {
        DailyQuestionDTO(
            questionID: entity.questionID,
            questionContent: entity.questionContent,
            user1Answer: entity.user1Answer,
            user2Answer: entity.user2Answer,
            bothAnswered: entity.bothAnswered,
            lastAnsweredAt: entity.lastAnsweredAt,
            isUser1: entity.isUser1
        )
    }
}

private struct FirestoreAnswerDTO: Decodable {
    let user1Answer: String?
    let user2Answer: String?
    let bothAnswered: Bool?
    let lastAnsweredAt: Date?
}
