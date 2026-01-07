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
        var petType: String
        var isHungry: Bool
        var statusMessage: String

        var level: Int
        var currentExp: Int
        var maxExp: Int

        var largeImageName: String {
            let stateName: String = isHungry ? "hungry" : "base"
            // Level 1~10: 알 (Egg) - 공통 이미지
            if level <= 10 {
                return "Egg"// \(stateName)"
            }
            // Level 30: 성체 + 왕관 (Adult + Crown)
            else if level >= 30 {
                return "\(petType)/\(stateName)"// _crown"
            }
            // Level 11~29: 성체 (Adult)
            else {
                return "\(petType)/\(stateName)"
            }
        }

        var iconImageName: String {
            let stateName: String = isHungry ? "iconHungry" : "iconBase"
            // Level 1~10: 알 (Egg)
            if level <= 10 {
                return "Egg"// \(stateName)"
            }
            // Level 30: 성체 + 왕관
            else if level >= 30 {
                return "\(petType)/\(stateName)"// _crown"
            }
            // Level 11~29: 성체
            else {
                return "\(petType)/\(stateName)"
            }
        }

        var statusImageName: String {
            isHungry ? "NeedFood" : "BaseHeart"
        }
    }

    // MARK: - Static Data
    var petName: String
    var udid: String
}
