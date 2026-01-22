//
//  PetSnapshotDTO.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Foundation

struct PetSnapshotDTO: Decodable {
    let petName: String
    let petType: String
    let isHungry: Bool
    let statusMessage: String
    let level: Int
    let currentExp: Int
    let maxExp: Int
    let lastFedAt: Date?
    let totalPlayTime: Int?
    let lastActiveAt: Date?
}
