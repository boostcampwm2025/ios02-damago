//
//  DailyQuestionUIModel.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

import Foundation

enum DailyQuestionUIModel: Equatable {
    case input(InputState)
    case result(ResultState)
    
    var questionID: String {
        switch self {
        case .input(let state): return state.questionID
        case .result(let state): return state.questionID
        }
    }
    
    var isUser1: Bool {
        switch self {
        case .input(let state): return state.isUser1
        case .result(let state): return state.isUser1
        }
    }
    
    struct InputState: Equatable {
        let questionID: String
        let questionContent: String
        let placeholder: String
        let isUser1: Bool
    }
    
    struct ResultState: Equatable {
        let questionID: String
        let questionContent: String
        let myAnswer: AnswerCardUIModel
        let opponentAnswer: AnswerCardUIModel
        let buttonTitle: String
        let isUser1: Bool
        let bothAnswered: Bool
        let lastAnsweredAt: Date?
    }
}

struct AnswerCardUIModel: Equatable {
    enum State {
        case locked
        case unlocked
    }
    
    let type: State
    let title: String
    let content: String?
    let placeholderText: String?
    let iconName: String?
}
