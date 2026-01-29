//
//  BalanceGameDTO.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

import Foundation
import OSLog

struct BalanceGameDTO: Decodable {
    let gameID: String
    let questionContent: String
    let option1: String
    let option2: String
    let myChoice: Int?
    let opponentChoice: Int?
    let isUser1: Bool
    let lastAnsweredAt: Date?
}

extension BalanceGameDTO {
    func toDomain() -> BalanceGameUIModel {
        if let myChoice {
            return .result(.init(
                gameID: gameID,
                questionContent: questionContent,
                option1: option1,
                option2: option2,
                myChoice: myChoice,
                opponentChoice: opponentChoice,
                isUser1: isUser1,
                lastAnsweredAt: lastAnsweredAt
            ))
        } else {
            return .input(.init(
                gameID: gameID,
                questionContent: questionContent,
                option1: option1,
                option2: option2,
                isUser1: isUser1,
                lastAnsweredAt: lastAnsweredAt
            ))
        }
    }
}
