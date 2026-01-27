//
//  HistoryModels.swift
//  Damago
//
//  Created by 박현수 on 1/26/26.
//

import Foundation

nonisolated struct DailyQuestionHistory: Hashable, Identifiable {
    let id: String
    let question: String
    let myAnswer: String
    let opponentAnswer: String
    let date: Date
}

nonisolated struct BalanceGameHistory: Hashable, Identifiable {
    let id: String
    let question: String
    let optionA: String
    let optionB: String
    let myChoice: Int
    let opponentChoice: Int
    
    var isMatch: Bool {
        myChoice == opponentChoice
    }
    
    var myChoiceText: String {
        switch myChoice {
        case 1: return optionA
        case 2: return optionB
        default: return "알 수 없음"
        }
    }
    
    var opponentChoiceText: String {
        switch opponentChoice {
        case 1: return optionA
        case 2: return optionB
        default: return "알 수 없음"
        }
    }
}
