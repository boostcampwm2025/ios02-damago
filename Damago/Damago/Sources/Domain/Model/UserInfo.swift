//
//  UserInfo.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

struct UserInfo {
    let uid: String
    let damagoID: String?
    let coupleID: String?
    let partnerUID: String?
    let nickname: String?
    let petStatus: PetStatus?
    let totalCoin: Int
    let lastFedAt: Date?
}
