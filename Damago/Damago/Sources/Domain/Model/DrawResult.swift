//
//  DrawResult.swift
//  Damago
//
//  Created by 김재영 on 2/3/26.
//

import Foundation

struct DrawResult: Equatable {
    let id = UUID()
    let damagoType: DamagoType
    let isNew: Bool
    
    var itemName: String {
        isNew ? "새로운 친구" : "이미 있는 친구\n[먹이 +5]"
    }
}
