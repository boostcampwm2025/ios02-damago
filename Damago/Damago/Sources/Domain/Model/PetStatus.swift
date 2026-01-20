//
//  PetStatus.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

import Foundation

struct PetStatus {
    let petName: String
    let petType: String
    let level: Int
    let currentExp: Int
    let maxExp: Int
    let isHungry: Bool
    let statusMessage: String
    let lastFedAt: Date?
    let totalPlayTime: Int
    let lastActiveAt: Date?
}
