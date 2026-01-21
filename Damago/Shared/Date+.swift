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
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    func toString(format: String = "yyyy.MM.dd.") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }

    func daysBetween(to date: Date) -> Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self)
        let end = calendar.startOfDay(for: date)

        guard let days = calendar.dateComponents([.day], from: start, to: end).day else {
            return nil
        }
        return days + 1
    }
}
