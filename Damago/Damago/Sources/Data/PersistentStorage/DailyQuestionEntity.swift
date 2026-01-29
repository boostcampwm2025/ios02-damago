//
//  DailyQuestionEntity.swift
//  Damago
//
//  Created by 김재영 on 1/22/26.
//

import Foundation
import SwiftData

@Model
final class DailyQuestionEntity {
    @Attribute(.unique)
    var questionID: String
    var questionContent: String
    var user1Answer: String?
    var user2Answer: String?
    var isUser1: Bool
    var bothAnswered: Bool
    var lastAnsweredAt: Date?
    var lastUpdated: Date?
    var draftAnswer: String?
    
    init(
        questionID: String,
        questionContent: String,
        user1Answer: String? = nil,
        user2Answer: String? = nil,
        bothAnswered: Bool = false,
        lastAnsweredAt: Date? = nil,
        isUser1: Bool = true,
        draftAnswer: String? = nil
    ) {
        self.questionID = questionID
        self.questionContent = questionContent
        self.user1Answer = user1Answer
        self.user2Answer = user2Answer
        self.bothAnswered = bothAnswered
        self.lastAnsweredAt = lastAnsweredAt
        self.isUser1 = isUser1
        self.draftAnswer = draftAnswer
        self.lastUpdated = Date()
    }
}
