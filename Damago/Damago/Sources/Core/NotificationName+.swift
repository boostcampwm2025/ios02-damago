//
//  NotificationName+.swift
//  Damago
//
//  Created by 박현수 on 1/15/26.
//

import Foundation

extension Notification.Name {
    static let fcmTokenDidUpdate = Notification.Name("fcmTokenDidUpdate")
    static let authenticationDidFail = Notification.Name("authenticationDidFail")
}
