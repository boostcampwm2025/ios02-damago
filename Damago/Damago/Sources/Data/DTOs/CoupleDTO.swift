//
//  CoupleDTO.swift
//  Damago
//
//  Created by 박현수 on 1/19/26.
//

import Foundation

struct CoupleDTO: Decodable {
    let id: String
    let user1UID: String
    let user2UID: String
    let damagoID: String
    let anniversaryDate: Date?
    let createdAt: Date?
    let totalCoin: Int
    let foodCount: Int
    let currentQuestionId: String?

    func toDomain() -> CoupleSharedInfo {
        CoupleSharedInfo(
            foodCount: self.foodCount,
            totalCoin: self.totalCoin,
            currentQuestionId: self.currentQuestionId
        )
    }
}
