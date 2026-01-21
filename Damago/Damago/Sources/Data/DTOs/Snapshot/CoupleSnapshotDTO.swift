//
//  CoupleSnapshotDTO.swift
//  Damago
//
//  Created by 박현수 on 1/21/26.
//

import Foundation

struct CoupleSnapshotDTO: Decodable {
    let totalCoin: Int
    let foodCount: Int
    let anniversaryDate: Date?
}
