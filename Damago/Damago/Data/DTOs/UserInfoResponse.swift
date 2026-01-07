//
//  UserInfoResponse.swift
//  Damago
//
//  Created by 김재영 on 1/7/26.
//

struct UserInfoResponse: Codable {
    let udid: String
    let damagoID: String?
    let partnerUDID: String?
    let nickname: String?
    let petStatus: DamagoStatusResponse?
}
