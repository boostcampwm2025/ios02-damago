//
//  DailyQuestionDTO.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

struct DailyQuestionDTO: Decodable {
    let questionID: String
    let questionContent: String
    let user1Answer: String?
    let user2Answer: String?
    let isUser1: Bool
}

extension DailyQuestionDTO {
    func toDomain() -> DailyQuestionUIModel {
        let myAnswerContent = isUser1 ? user1Answer : user2Answer
        let opponentAnswerContent = isUser1 ? user2Answer : user1Answer
        
        if let myAnswerContent {
            return .result(.init(
                questionID: questionID,
                questionContent: questionContent,
                myAnswer: .init(
                    type: .unlocked,
                    title: "나의 답변",
                    content: myAnswerContent,
                    placeholderText: nil,
                    iconName: nil
                ),
                opponentAnswer: mapOpponentAnswer(content: opponentAnswerContent),
                buttonTitle: "답변 확인",
                isUser1: isUser1
            ))
        } else {
            return .input(.init(
                questionID: questionID,
                questionContent: questionContent,
                placeholder: "여기에 답변을 입력하세요.",
                isUser1: isUser1
            ))
        }
    }
    
    private func mapOpponentAnswer(content: String?) -> AnswerCardUIModel {
        if let content {
            return .init(
                type: .unlocked,
                title: "상대의 답변",
                content: content,
                placeholderText: nil,
                iconName: nil
            )
        } else {
            return .init(
                type: .locked,
                title: "상대의 답변",
                content: nil,
                placeholderText: "상대방이 아직 고민 중이에요...",
                iconName: "hourglass"
            )
        }
    }
}
