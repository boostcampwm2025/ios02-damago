//
//  BalanceGameRepository.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

import Combine
import DamagoNetwork
import Foundation

final class BalanceGameRepository: BalanceGameRepositoryProtocol {
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
    
    func fetchBalanceGame() async throws -> BalanceGameDTO {
        let token = try await tokenProvider.idToken()
        return try await networkProvider.request(BalanceGameAPI.fetch(accessToken: token))
    }
    
    func submitChoice(gameID: String, choice: Int) async throws -> Bool {
        let token = try await tokenProvider.idToken()
        return try await networkProvider.requestSuccess(
            BalanceGameAPI.submit(
                accessToken: token,
                gameID: gameID,
                choice: choice
            )
        )
    }
    
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
        .map { (result: Result<FirestoreBalanceGameAnswerDTO, Error>) in
            switch result {
            case .success(let dto):
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
}

private struct FirestoreBalanceGameAnswerDTO: Decodable {
    let user1Answer: Int?
    let user2Answer: Int?
    let bothAnswered: Bool?
    let lastAnsweredAt: String?
}
