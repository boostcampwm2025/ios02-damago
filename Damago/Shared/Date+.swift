//
//  Date+.swift
//  Damago
//
//  Created by 김재영 on 1/8/26.
//

import Foundation

extension Date {
    static func fromISO8601(_ dateString: String?) -> Date? {
        guard let dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
}
