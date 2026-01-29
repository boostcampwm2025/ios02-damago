//
//  BalanceGameUIModel.swift
//  Damago
//
//  Created by Eden Landelyse on 1/26/26.
//

import Foundation

enum BalanceGameUIModel: Equatable {
    case input(InputState)
    case result(ResultState)
    
    struct InputState: Equatable {
        let gameID: String
        let questionContent: String
        let option1: String
        let option2: String
        let isUser1: Bool
        let lastAnsweredAt: Date?
    }
    
    struct ResultState: Equatable {
        let gameID: String
        let questionContent: String
        let option1: String
        let option2: String
        let myChoice: Int
        let opponentChoice: Int?
        let isUser1: Bool
        let lastAnsweredAt: Date?
    }
}
