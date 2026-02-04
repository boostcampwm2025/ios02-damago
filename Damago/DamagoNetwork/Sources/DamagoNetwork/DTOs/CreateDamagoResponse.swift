//
//  CreateDamagoResponse.swift
//  DamagoNetwork
//
//  Created by 김재영 on 2/3/26.
//

import Foundation

public struct CreateDamagoResponse: Decodable {
    public let id: String
    public let totalCoin: Int
    public let damagoType: String
    public let isNew: Bool
}
