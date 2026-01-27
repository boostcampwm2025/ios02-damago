//
//  MockBalanceGameRepository.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

import Combine
import Foundation

final class MockBalanceGameRepository: BalanceGameRepositoryProtocol {
    // 현재 선택 상태를 추적하기 위한 내부 변수 (Mock용)
    private let choiceSubject = CurrentValueSubject<Int?, Never>(nil)

    func fetchBalanceGame() async throws -> BalanceGameDTO {
        BalanceGameDTO(
            gameID: "mock_game",
            questionContent: "평생 한 종류의 음식만 먹어야 한다면?",
            option1: "매일 아침 갓 구운 빵과 커피",
            option2: "매일 저녁 육즙 가득한 스테이크",
            myChoice: nil,
            opponentChoice: nil,
            isUser1: true,
            lastAnsweredAt: nil
        )
    }

    func submitChoice(gameID: String, choice: Int) async throws -> Bool {
        choiceSubject.send(choice)
        return true
    }

    func observeAnswer(
        coupleID: String,
        gameID: String,
        questionContent: String,
        option1: String,
        option2: String,
        isUser1: Bool
    ) -> AnyPublisher<Result<BalanceGameDTO, Error>, Never> {
        choiceSubject
            .map { myChoice -> Result<BalanceGameDTO, Error> in
                if let myChoice = myChoice {
                    let resultDTO = BalanceGameDTO(
                        gameID: gameID,
                        questionContent: questionContent,
                        option1: option1,
                        option2: option2,
                        myChoice: myChoice,
                        opponentChoice: 2, // 상대방은 2번 선택 시뮬레이션
                        isUser1: isUser1,
                        lastAnsweredAt: ISO8601DateFormatter().string(from: Date())
                    )
                    return .success(resultDTO)
                } else {
                    let inputDTO = BalanceGameDTO(
                        gameID: gameID,
                        questionContent: questionContent,
                        option1: option1,
                        option2: option2,
                        myChoice: nil,
                        opponentChoice: nil,
                        isUser1: isUser1,
                        lastAnsweredAt: nil
                    )
                    return .success(inputDTO)
                }
            }
            .eraseToAnyPublisher()
    }
}
