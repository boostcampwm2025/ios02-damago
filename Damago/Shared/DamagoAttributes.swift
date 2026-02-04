//
//  DamagoAttributes.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import Foundation

struct DamagoAttributes: ActivityAttributes {
    // test 환경에서는 10초, 배포에선 4시간
    static let feedCooldown: TimeInterval =
        (ProcessInfo.processInfo.environment["USE_LOCAL_EMULATOR"] != nil) ? 10 : 4 * 60 * 60

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
}

public let totalDamagos: [DamagoType] = DamagoType.allCases

extension DamagoAttributes {
    public enum Screen: String, Codable, Hashable {
        case idle
        case choosePokeMessage
        case sending
        case error
    }
}
