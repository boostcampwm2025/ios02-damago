//
//  HistoryDTOs.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import Foundation

struct DailyQuestionHistoryDTO: Decodable {
    let questionID: String
    let questionContent: String
    let user1Answer: String
    let user2Answer: String
    let answeredAt: String
    let isUser1: Bool
    
    func toDomain() -> DailyQuestionHistory {
        let myAnswer = isUser1 ? user1Answer : user2Answer
        let opponentAnswer = isUser1 ? user2Answer : user1Answer
        
        return DailyQuestionHistory(
            id: questionID,
            question: questionContent,
            myAnswer: myAnswer,
            opponentAnswer: opponentAnswer,
            date: Date.fromISO8601(answeredAt) ?? Date()
        )
    }
}

struct BalanceGameHistoryDTO: Decodable {
    let gameID: String
    let question: String
    let optionA: String
    let optionB: String
    let user1Answer: Int
    let user2Answer: Int
    let isUser1: Bool
    
    func toDomain() -> BalanceGameHistory {
        let myChoice = isUser1 ? user1Answer : user2Answer
        let opponentChoice = isUser1 ? user2Answer : user1Answer
        
        return BalanceGameHistory(
            id: gameID,
            question: question,
            optionA: optionA,
            optionB: optionB,
            myChoice: myChoice,
            opponentChoice: opponentChoice
        )
    }
}
