//
//  BalanceGameEntity.swift
//  Damago
//
//  Created by Eden Landelyse on 1/28/26.
//

import Foundation
import SwiftData

@Model
final class BalanceGameEntity {
    @Attribute(.unique)
    var gameID: String
    var questionContent: String
    var option1: String
    var option2: String
    var user1Choice: Int?
    var user2Choice: Int?
    var isUser1: Bool
    var lastAnsweredAt: Date?
    var lastUpdated: Date?

    init(
        gameID: String,
        questionContent: String,
        option1: String,
        option2: String,
        user1Choice: Int? = nil,
        user2Choice: Int? = nil,
        isUser1: Bool = true,
        lastAnsweredAt: Date? = nil
    ) {
        self.gameID = gameID
        self.questionContent = questionContent
        self.option1 = option1
        self.option2 = option2
        self.user1Choice = user1Choice
        self.user2Choice = user2Choice
        self.isUser1 = isUser1
        self.lastAnsweredAt = lastAnsweredAt
        self.lastUpdated = Date()
    }
}
