//
//  AppGroupUserDefaults.swift
//  Damago
//
//  Created by Eden Landelyse on 1/16/26.
//

import Foundation
import OSLog

enum AppGroupUserDefaults {
    static let id = "group.kr.codesquad.boostcamp10.Damago"
    static let shortcutsKey = "pokeShortcuts"

    static func sharedDefaults() -> UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: Self.id) else {
            SharedLogger.userDefaults.error("App Group User Defaults 생성 실패 / 설정 및 id  확인")
            return UserDefaults.standard
        }

        return userDefaults
    }
}
