//
//  PokeAppIntent.swift
//  DamagoWidget
//
//  Created by 박현수 on 12/18/25.
//

import AppIntents
import Foundation
import DamagoNetwork

struct PokeAppIntent: AppIntent {
    static var title: LocalizedStringResource = "콕 찌르기"
    static var description: IntentDescription = "상대방을 콕 찔러 알림을 보냅니다."

    @Parameter(title: "UDID")
    var udid: String

    init(udid: String) {
        self.udid = udid
    }

    init() {}

    func perform() async throws -> some IntentResult {
        let networkProvider = NetworkProvider()
        try await networkProvider.requestSuccess(PushAPI.poke(udid: udid))
        return .result()
    }
}
