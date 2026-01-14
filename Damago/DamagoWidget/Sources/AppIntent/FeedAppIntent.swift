//
//  FeedAppIntent.swift
//  Damago
//
//  Created by Eden Landelyse on 1/8/26.
//

import AppIntents
import Foundation

struct FeedAppIntent: AppIntent {
    static var title: LocalizedStringResource = "밥 주기"
    static var description: IntentDescription = "다마고에게 밥을 줍니다."

    init() { }

    func perform() async throws -> some IntentResult {
        // 밥주기 구현
        return .result()
    }
}
