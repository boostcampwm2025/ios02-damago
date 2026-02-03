//
//  BalanceGameRepository.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

import Combine
import DamagoNetwork
import Foundation
import OSLog

final class BalanceGameRepository: BalanceGameRepositoryProtocol, DataSyncStrategy {
    private let networkProvider: NetworkProvider
    private let tokenProvider: TokenProvider
    private let firestoreService: FirestoreService
    private let localDataSource: BalanceGameLocalDataSourceProtocol
    
    init(
        networkProvider: NetworkProvider,
        tokenProvider: TokenProvider,
        firestoreService: FirestoreService,
        localDataSource: BalanceGameLocalDataSourceProtocol
    ) {
        self.networkProvider = networkProvider
        self.tokenProvider = tokenProvider
        self.firestoreService = firestoreService
        self.localDataSource = localDataSource
    }
    
    func fetchBalanceGame() -> AsyncStream<BalanceGameDTO> {
        createFetchStream(
            fetchLocal: { [weak self] in
                guard let self else { return nil }
                guard let entity = try await self.localDataSource.fetchLatestGame() else { return nil }
                return self.mapToDTO(entity: entity)
            },
            checkIsUpToDate: { dto in
                guard let lastAnswered = dto.lastAnsweredAt else { return false }
                return Calendar.current.isDateInToday(lastAnswered)
            },
            fetchNetwork: { [weak self] in
                guard let self else { throw URLError(.unknown) }
                let token = try await self.tokenProvider.idToken()
                return try await self.networkProvider.request(BalanceGameAPI.fetch(accessToken: token))
            },
            saveToLocal: { [weak self] dto in
                await self?.saveToLocalGame(dto: dto)
            },
            onNetworkError: { error in
                SharedLogger.interaction.error("Balance Game 네트워크 조회 실패: \(error.localizedDescription)")
            }
        )
    }
    
    func submitChoice(gameID: String, choice: Int, isUser1: Bool) async throws -> Bool {
        // 1. 이전 상태 백업 (롤백용)
        let previousEntity = try await localDataSource.fetchGame(id: gameID)
        let previousUser1Choice = previousEntity?.user1Choice
        let previousUser2Choice = previousEntity?.user2Choice
        let previousLastAnsweredAt = previousEntity?.lastAnsweredAt
        
        return try await submitWithOptimisticUpdate(
            backupState: previousEntity,
            updateLocal: { [weak self] in
                try await self?.localDataSource.updateChoice(
                    gameID: gameID,
                    user1Choice: isUser1 ? choice : previousUser1Choice,
                    user2Choice: isUser1 ? previousUser2Choice : choice,
                    lastAnsweredAt: Date()
                )
            },
            networkCall: { [weak self] in
                guard let self else { return false }
                let token = try await self.tokenProvider.idToken()
                return try await self.networkProvider.requestSuccess(
                    BalanceGameAPI.submit(
                        accessToken: token,
                        gameID: gameID,
                        choice: choice
                    )
                )
            },
            rollbackLocal: { [weak self] _ in
                try await self?.localDataSource.updateChoice(
                    gameID: gameID,
                    user1Choice: previousUser1Choice,
                    user2Choice: previousUser2Choice,
                    lastAnsweredAt: previousLastAnsweredAt
                )
            },
            onFailure: { error in
                SharedLogger.interaction.error("API 제출 실패, 로컬 데이터 롤백: \(error.localizedDescription)")
            }
        )
    }
    
    // swiftlint:disable trailing_closure
    func observeAnswer(
        coupleID: String,
        gameID: String,
        questionContent: String,
        option1: String,
        option2: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<BalanceGameDTO, Error>, Never> {
        firestoreService.observe(
            collection: "couples/\(coupleID)/balanceGameAnswers",
            document: gameID
        )
        .handleEvents(receiveOutput: { [weak self] result in
            if case .success(let response) = result {
                Task {
                    await self?.updateLocalChoice(
                        gameID: gameID,
                        response: response
                    )
                }
            }
        })
        .map { (result: Result<FirestoreBalanceGameAnswerDTO, Error>) in
            switch result {
            case .success(let dto):
                if dto.lastAnsweredAt == nil && dto.bothAnswered == true {
                    SharedLogger.interaction.debug(
                        "Repository: bothAnswered는 true인데 lastAnsweredAt이 nil입니다. 데이터 확인 필요."
                    )
                }
                
                let combinedDTO = BalanceGameDTO(
                    gameID: gameID,
                    questionContent: questionContent,
                    option1: option1,
                    option2: option2,
                    myChoice: isUser1 ? dto.user1Answer : dto.user2Answer,
                    opponentChoice: isUser1 ? dto.user2Answer : dto.user1Answer,
                    isUser1: isUser1,
                    lastAnsweredAt: dto.lastAnsweredAt
                )
                return .success(combinedDTO)
            case .failure(let error):
                return .failure(error)
            }
        }
        .eraseToAnyPublisher()
    }
    // swiftlint:enable trailing_closure

    @MainActor
    private func saveToLocalGame(dto: BalanceGameDTO) async {
        do {
            let entity = BalanceGameEntity(
                gameID: dto.gameID,
                questionContent: dto.questionContent,
                option1: dto.option1,
                option2: dto.option2,
                user1Choice: dto.isUser1 ? dto.myChoice : dto.opponentChoice,
                user2Choice: dto.isUser1 ? dto.opponentChoice : dto.myChoice,
                isUser1: dto.isUser1,
                lastAnsweredAt: dto.lastAnsweredAt
            )
            try await localDataSource.saveGame(entity)
        } catch {
            SharedLogger.interaction.error("Local save failed: \(error)")
        }
    }
    
    @MainActor
    private func updateLocalChoice(gameID: String, response: FirestoreBalanceGameAnswerDTO) async {
        do {
            try await localDataSource.updateChoice(
                gameID: gameID,
                user1Choice: response.user1Answer,
                user2Choice: response.user2Answer,
                lastAnsweredAt: response.lastAnsweredAt
            )
        } catch {
            SharedLogger.interaction.error("Local update failed: \(error)")
        }
    }
    
    private func mapToDTO(entity: BalanceGameEntity) -> BalanceGameDTO {
        BalanceGameDTO(
            gameID: entity.gameID,
            questionContent: entity.questionContent,
            option1: entity.option1,
            option2: entity.option2,
            myChoice: entity.isUser1 ? entity.user1Choice : entity.user2Choice,
            opponentChoice: entity.isUser1 ? entity.user2Choice : entity.user1Choice,
            isUser1: entity.isUser1,
            lastAnsweredAt: entity.lastAnsweredAt
        )
    }
}

private struct FirestoreBalanceGameAnswerDTO: Decodable {
    let user1Answer: Int?
    let user2Answer: Int?
    let bothAnswered: Bool?
    let lastAnsweredAt: Date?
}
