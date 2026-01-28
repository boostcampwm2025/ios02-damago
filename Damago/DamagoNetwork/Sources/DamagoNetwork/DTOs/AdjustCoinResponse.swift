//
//  AdjustCoinResponse.swift
//  DamagoNetwork
//
//  Created by 박현수 on 1/28/26.
//

import Foundation

public struct AdjustCoinResponse: Decodable {
    public let totalCoin: Int
    
    public init(totalCoin: Int) {
        self.totalCoin = totalCoin
    }
}
