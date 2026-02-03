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

final class BalanceGameRepository: BalanceGameRepositoryProtocol {
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
        AsyncStream { continuation in
            Task {
                // 1. 로컬 데이터 조회 및 즉시 방출 (오늘 데이터인 경우만)
                if let entity = try? await localDataSource.fetchLatestGame(),
                   let lastUpdated = entity.lastUpdated,
                   Calendar.current.isDateInToday(lastUpdated) {
                    
                    let dto = BalanceGameDTO(
                        gameID: entity.gameID,
                        questionContent: entity.questionContent,
                        option1: entity.option1,
                        option2: entity.option2,
                        myChoice: entity.isUser1 ? entity.user1Choice : entity.user2Choice,
                        opponentChoice: entity.isUser1 ? entity.user2Choice : entity.user1Choice,
                        isUser1: entity.isUser1,
                        lastAnsweredAt: entity.lastAnsweredAt
                    )
                    continuation.yield(dto)
                }

                // 2. 네트워크 데이터 조회 및 방출
                do {
                    let token = try await tokenProvider.idToken()
                    let dto: BalanceGameDTO = try await networkProvider.request(
                        BalanceGameAPI.fetch(accessToken: token)
                    )
                    await saveToLocalGame(dto: dto)
                    continuation.yield(dto)
                } catch {
                    SharedLogger.interaction.error("Balance Game 네트워크 조회 실패: \(error.localizedDescription)")
                }

                continuation.finish()
            }
        }
    }
    
    func submitChoice(gameID: String, choice: Int, isUser1: Bool) async throws -> Bool {
        // 1. 이전 상태 백업 (롤백용)
        let previousEntity = try await localDataSource.fetchGame(id: gameID)
        let previousUser1Choice = previousEntity?.user1Choice
        let previousUser2Choice = previousEntity?.user2Choice
        let previousLastAnsweredAt = previousEntity?.lastAnsweredAt
        
        // 2. 로컬 업데이트 선반영 (Optimistic Update)
        try await localDataSource.updateChoice(
            gameID: gameID,
            user1Choice: isUser1 ? choice : previousUser1Choice,
            user2Choice: isUser1 ? previousUser2Choice : choice,
            lastAnsweredAt: Date()
        )
        
        do {
            let token = try await tokenProvider.idToken()
            let success = try await networkProvider.requestSuccess(
                BalanceGameAPI.submit(
                    accessToken: token,
                    gameID: gameID,
                    choice: choice
                )
            )
            return success
        } catch {
            SharedLogger.interaction.error("API 제출 실패, 로컬 데이터 롤백: \(error.localizedDescription)")
            
            // 3. 실패 시 롤백: 이전 상태로 복구
            try await localDataSource.updateChoice(
                gameID: gameID,
                user1Choice: previousUser1Choice,
                user2Choice: previousUser2Choice,
                lastAnsweredAt: previousLastAnsweredAt
            )
            throw error
        }
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
                var lastAnsweredAt = dto.lastAnsweredAt
                
                // Fallback: bothAnswered는 true인데 lastAnsweredAt이 없는 경우 (레거시 데이터 등)
                if lastAnsweredAt == nil && dto.bothAnswered == true {
                    let t1 = dto.user1AnsweredAt?.timeIntervalSince1970 ?? 0
                    let t2 = dto.user2AnsweredAt?.timeIntervalSince1970 ?? 0
                    if t1 > 0 || t2 > 0 {
                        lastAnsweredAt = Date(timeIntervalSince1970: max(t1, t2))
                    }
                }
                
                if lastAnsweredAt == nil && dto.bothAnswered == true {
                    SharedLogger.interaction.debug("Repository: bothAnswered는 true인데 lastAnsweredAt을 복구할 수 없습니다.")
                }
                
                let combinedDTO = BalanceGameDTO(
                    gameID: gameID,
                    questionContent: questionContent,
                    option1: option1,
                    option2: option2,
                    myChoice: isUser1 ? dto.user1Answer : dto.user2Answer,
                    opponentChoice: isUser1 ? dto.user2Answer : dto.user1Answer,
                    isUser1: isUser1,
                    lastAnsweredAt: lastAnsweredAt
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
        var lastAnsweredAt = response.lastAnsweredAt
        
        if lastAnsweredAt == nil && response.bothAnswered == true {
            let t1 = response.user1AnsweredAt?.timeIntervalSince1970 ?? 0
            let t2 = response.user2AnsweredAt?.timeIntervalSince1970 ?? 0
            if t1 > 0 || t2 > 0 {
                lastAnsweredAt = Date(timeIntervalSince1970: max(t1, t2))
            }
        }

        do {
            try await localDataSource.updateChoice(
                gameID: gameID,
                user1Choice: response.user1Answer,
                user2Choice: response.user2Answer,
                lastAnsweredAt: lastAnsweredAt
            )
        } catch {
            SharedLogger.interaction.error("Local update failed: \(error)")
        }
    }
}

private struct FirestoreBalanceGameAnswerDTO: Decodable {
    let user1Answer: Int?
    let user2Answer: Int?
    let bothAnswered: Bool?
    let lastAnsweredAt: Date?
    let user1AnsweredAt: Date?
    let user2AnsweredAt: Date?
}
