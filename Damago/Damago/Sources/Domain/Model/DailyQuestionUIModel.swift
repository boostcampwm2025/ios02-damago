//
//  DailyQuestionUIModel.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

enum DailyQuestionUIModel: Equatable {
    case input(InputState)
    case result(ResultState)
    
    struct InputState: Equatable {
        let placeholder: String
        let buttonTitle: String
    }
    
    struct ResultState: Equatable {
        let myAnswer: AnswerCardUIModel
        let opponentAnswer: AnswerCardUIModel
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
