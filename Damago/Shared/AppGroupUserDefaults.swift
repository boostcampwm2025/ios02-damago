//
//  AppGroupUserDefaults.swift
//  Damago
//
//  Created by Eden Landelyse on 1/16/26.
//

import Foundation
import OSLog

enum AppGroupUserDefaults {
    static let shortcutsKey = "pokeShortcuts"

    static func sharedDefaults(suiteName: String = AppGroupConstants.default) -> UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            SharedLogger.userDefaults.error("App Group User Defaults 생성 실패 / 설정 및 id  확인")
            return UserDefaults.standard
        }

        return userDefaults
    }
}
