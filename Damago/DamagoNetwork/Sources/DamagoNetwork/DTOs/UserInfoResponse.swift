//
//  UserInfoResponse.swift
//  Damago
//
//  Created by 김재영 on 1/7/26.
//

import Foundation

public struct UserInfoResponse: Codable {
    public let uid: String
    public let damagoID: String?
    public let coupleID: String?
    public let partnerUID: String?
    public let nickname: String?
    public let petStatus: DamagoStatusResponse?
    public let totalCoin: Int?
    public let lastFedAt: Date?
}