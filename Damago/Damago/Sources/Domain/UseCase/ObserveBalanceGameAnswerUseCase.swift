//
//  ObserveBalanceGameAnswerUseCase.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

import Combine

protocol ObserveBalanceGameAnswerUseCase {
    func execute(
        coupleID: String,
        gameID: String,
        questionContent: String,
        option1: String,
        option2: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<BalanceGameUIModel, Error>, Never>
}

final class ObserveBalanceGameAnswerUseCaseImpl: ObserveBalanceGameAnswerUseCase {
    private let repository: BalanceGameRepositoryProtocol
    
    init(repository: BalanceGameRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(
        coupleID: String,
        gameID: String,
        questionContent: String,
        option1: String,
        option2: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<BalanceGameUIModel, Error>, Never> {
        repository.observeAnswer(
            coupleID: coupleID,
            gameID: gameID,
            questionContent: questionContent,
            option1: option1,
            option2: option2,
            isUser1: isUser1
        )
        .map { result in
            switch result {
            case .success(let dto):
                return .success(dto.toDomain())
            case .failure(let error):
                return .failure(error)
            }
        }
        .eraseToAnyPublisher()
    }
}
