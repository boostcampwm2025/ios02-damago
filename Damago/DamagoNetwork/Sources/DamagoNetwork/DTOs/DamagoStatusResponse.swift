//
//  DamagoStatusResponse.swift
//  Damago
//
//  Created by 김재영 on 1/7/26.
//

public struct DamagoStatusResponse: Codable {
    public let petName: String
    public let petType: String
    public let level: Int
    public let currentExp: Int
    public let maxExp: Int
    public let isHungry: Bool
    public let statusMessage: String
    public let lastFedAt: String?
    public let totalPlayTime: Int
    public let lastActiveAt: String?
}