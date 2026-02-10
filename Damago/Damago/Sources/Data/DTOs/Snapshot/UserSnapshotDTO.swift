//
//  UserSnapshotDTO.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Foundation

struct UserSnapshotDTO: Decodable {
    let uid: String
    let coupleID: String?
    let damagoID: String?
    let partnerUID: String?
    let useFCM: Bool
    let useLiveActivity: Bool
    let nickname: String?
    let todayPokeCount: Int?
    let lastPokeDate: String?
}
