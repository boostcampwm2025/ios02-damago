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
        var damagoType: DamagoType
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
            return "\(damagoType.rawValue)\(stateName)"
        }

        var statusImageName: String {
            isHungry ? "food" : "heart"
        }
    }

    // MARK: - Static Data
    var damagoName: String
}

public enum DamagoType: String, CaseIterable, Codable {
    case basicBlack = "CatBasicBlack"
    case basicPink = "CatBasicPink"
    case basicYellow = "CatBasicYellow"
    
    case siamese = "CatSiamese"
    case tiger = "CatTiger"
    case batman = "CatBatman"
    case christmas = "CatChristmas"
    case egypt = "CatEgypt"
    case oddEye = "CatOddEye"
    case threeColored = "CatThreeColored"
    case wizard = "CatWizard"

    public var imageName: String {
        "\(self.rawValue)Base"
    }

    public var isBasic: Bool {
        switch self {
        case .basicBlack, .basicPink, .basicYellow:
            return true
        default:
            return false
        }
    }
    
    // TODO: 서버에서 받아오기
    public var isAvailable: Bool {
        switch self {
        case .siamese, .tiger, .batman, .christmas, .egypt, .oddEye, .threeColored, .wizard:
            return true
        default:
            return false
        }
    }
}

extension DamagoAttributes {
    public enum Screen: String, Codable, Hashable {
        case idle
        case choosePokeMessage
        case sending
        case error
    }
}
