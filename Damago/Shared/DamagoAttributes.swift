//
//  DamagoAttributes.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import Foundation

struct DamagoAttributes: ActivityAttributes {
    static let feedCooldown: TimeInterval = 10

    // MARK: - Dynamic State
    public struct ContentState: Codable, Hashable {
        var petType: String
        var isHungry: Bool
        var statusMessage: String

        var level: Int
        var currentExp: Int
        var maxExp: Int
        var lastFedAt: String?
        var screen: Screen? = .idle
        var lastFedAtDate: Date? {
            Date.fromISO8601(lastFedAt)
        }

        var imageName: String {
            let stateName: String = isHungry ? "Hungry" : "Base"
            return "\(petType)\(stateName)"
        }

        var statusImageName: String {
            isHungry ? "food" : "heart"
        }
    }

    // MARK: - Static Data
    var petName: String
}

extension DamagoAttributes {
    public enum Screen: String, Codable, Hashable {
        case idle
        case choosePokeMessage
        case sending
        case error
    }
}
