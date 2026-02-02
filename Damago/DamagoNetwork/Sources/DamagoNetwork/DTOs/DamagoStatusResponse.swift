//
//  DamagoStatusResponse.swift
//  Damago
//
//  Created by 김재영 on 1/7/26.
//

import Foundation

public struct DamagoStatusResponse: Codable {
    public let damagoName: String
    public let damagoType: String
    public let level: Int
    public let currentExp: Int
    public let maxExp: Int
    public let isHungry: Bool
    public let statusMessage: String
    public let lastFedAt: Date?
    public let totalPlayTime: Int?
    public let lastActiveAt: Date?
    
    public init(
        damagoName: String,
        damagoType: String,
        level: Int,
        currentExp: Int,
        maxExp: Int,
        isHungry: Bool,
        statusMessage: String,
        lastFedAt: Date?,
        totalPlayTime: Int?,
        lastActiveAt: Date?
    ) {
        self.damagoName = damagoName
        self.damagoType = damagoType
        self.level = level
        self.currentExp = currentExp
        self.maxExp = maxExp
        self.isHungry = isHungry
        self.statusMessage = statusMessage
        self.lastFedAt = lastFedAt
        self.totalPlayTime = totalPlayTime
        self.lastActiveAt = lastActiveAt
    }
}
