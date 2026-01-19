//
//  DamagoDTO.swift
//  Damago
//
//  Created by 박현수 on 1/20/26.
//

import Foundation

struct DamagoDTO: Decodable {
    let petName: String
    let petType: String
    let level: Int
    let currentExp: Int
    let maxExp: Int
    let isHungry: Bool
    let statusMessage: String
    let lastFedAt: Date?
    let totalPlayTime: Int?
    let lastActiveAt: Date?

    func toDomain() -> PetStatus {
        PetStatus(
            petName: petName,
            petType: petType,
            level: level,
            currentExp: currentExp,
            maxExp: maxExp,
            isHungry: isHungry,
            statusMessage: statusMessage,
            lastFedAt: lastFedAt?.ISO8601Format(),
            totalPlayTime: totalPlayTime ?? 0,
            lastActiveAt: lastActiveAt?.ISO8601Format()
        )
    }
}
