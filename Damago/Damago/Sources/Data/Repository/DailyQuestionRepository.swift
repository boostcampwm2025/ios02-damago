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
    
    func fetchDailyQuestion() -> AnyPublisher<DailyQuestionDTO, Error> {
        let local = Future<DailyQuestionDTO?, Never> { [weak self] promise in
            Task {
                let entity = try? await self?.localDataSource.fetchLatestQuestion()
                
                if let entity,
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
                    promise(.success(dto))
                } else {
                    promise(.success(nil))
                }
            }
        }
        .compactMap { $0 }
        .setFailureType(to: Error.self)

        let network = Future<DailyQuestionDTO, Error> { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    let token = try await self.tokenProvider.idToken()
                    let dto: DailyQuestionDTO = try await self.networkProvider.request(
                        DailyQuestionAPI.fetch(accessToken: token)
                    )
                    await self.saveToLocalAnswer(dto: dto)
                    promise(.success(dto))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        
        return local.merge(with: network).eraseToAnyPublisher()
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
