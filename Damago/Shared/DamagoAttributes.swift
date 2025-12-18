//
//  DamagoAttributes.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit

struct DamagoAttributes: ActivityAttributes {
    // MARK: - Dynamic State
    public struct ContentState: Codable, Hashable {
        var characterName: String
        var isHungry: Bool
        var statusMessage: String

        var largeImageName: String {
            let stateName = isHungry ? "hungry" : "base"
            return "\(characterName)/\(stateName)"
        }

        var iconImageName: String {
            let stateName = isHungry ? "iconHungry" : "iconBase"
            return "\(characterName)/\(stateName)"
        }

        var statusImageName: String {
            isHungry ? "NeedFood" : "BaseHeart"
        }
    }

    // MARK: - Static Data
    var petName: String
    var udid: String
}
