//
//  GlobalState.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Foundation

struct GlobalState: Equatable {
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
    
    // MARK: - Pet Content
    let petName: String?
    let petType: String?
    let level: Int?
    let currentExp: Int?
    let maxExp: Int?
    let isHungry: Bool?
    let statusMessage: String?
    let lastFedAt: Date?
    let totalPlayTime: Int?
    let lastActiveAt: Date?
    
    static let empty = GlobalState(
        nickname: nil,
        opponentName: nil,
        useFCM: true,
        useLiveActivity: true,
        coupleID: nil,
        totalCoin: nil,
        foodCount: nil,
        anniversaryDate: nil,
        petName: nil,
        petType: nil,
        level: nil,
        currentExp: nil,
        maxExp: nil,
        isHungry: nil,
        statusMessage: nil,
        lastFedAt: nil,
        totalPlayTime: nil,
        lastActiveAt: nil
    )
}
