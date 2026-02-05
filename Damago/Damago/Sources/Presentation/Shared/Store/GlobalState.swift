//
//  GlobalState.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Foundation

nonisolated struct GlobalState: Equatable {
    // MARK: - User Content
    let nickname: String?
    let opponentName: String?
    let useFCM: Bool
    let useLiveActivity: Bool
    
    // MARK: - Couple Content
    let coupleID: String?
    let totalCoin: Int?
    let foodCount: Int?
    let anniversaryDate: Date?
    let currentQuestionID: String?

    // MARK: - Damago Content
    let damagoID: String?
    let damagoName: String?
    let damagoType: DamagoType?
    let level: Int?
    let currentExp: Int?
    let maxExp: Int?
    let isHungry: Bool?
    let statusMessage: String?
    let lastFedAt: Date?
    let totalPlayTime: Int?
    let lastActiveAt: Date?
    let ownedDamagos: [DamagoType: Int]?
    
    static let empty = GlobalState(
        nickname: nil,
        opponentName: nil,
        useFCM: false,
        useLiveActivity: false,
        coupleID: nil,
        totalCoin: nil,
        foodCount: nil,
        anniversaryDate: nil,
        currentQuestionID: nil,
        damagoID: nil,
        damagoName: nil,
        damagoType: nil,
        level: nil,
        currentExp: nil,
        maxExp: nil,
        isHungry: nil,
        statusMessage: nil,
        lastFedAt: nil,
        totalPlayTime: nil,
        lastActiveAt: nil,
        ownedDamagos: nil
    )
}
