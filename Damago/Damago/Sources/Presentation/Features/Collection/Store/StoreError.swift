//
//  StoreError.swift
//  Damago
//
//  Created by 김재영 on 2/3/26.
//

import Foundation

enum StoreError: LocalizedError {
    case notEnoughCoin
    case collectionComplete
    case creationFailed
    
    var errorDescription: String? {
        switch self {
        case .notEnoughCoin: return "코인이 부족해요!"
        case .collectionComplete: return "모든 친구를 만났어요!"
        case .creationFailed: return "친구를 데려오는데 실패했어요."
        }
    }
}
