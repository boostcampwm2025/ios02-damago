//
//  Logger+Shared.swift
//  Damago
//
//  Created by 박현수 on 12/16/25.
//

import OSLog

nonisolated enum SharedLogger {
    static var subSystem: String { Bundle.main.bundleIdentifier ?? "" }

    static let apns = Logger(subsystem: subSystem, category: "apnsLogger")
    static let firebase = Logger(subsystem: subSystem, category: "firebaseLogger")
    static let liveActivityManger = Logger(subsystem: subSystem, category: "liveActivityMangerLogger")
    static let liveActivityAppIntent = Logger(subsystem: subSystem, category: "liveActivityAppIntentLogger")
    static let userDefaults = Logger(subsystem: subSystem, category: "userDefaultsLogger")
    static let interaction = Logger(subsystem: subSystem, category: "interactionLogger")
    static let common = Logger(subsystem: subSystem, category: "common")
}
