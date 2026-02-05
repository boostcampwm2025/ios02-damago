//
//  MockTokenProvider.swift
//  DamagoRepositoryTests
//
//  Created by Eden Landelyse on 2/4/26.
//

import Foundation
@testable import Damago
@testable import DamagoNetwork

final class MockTokenProvider: TokenProvider, @unchecked Sendable {
    var idTokenHandler: (() async throws -> String)?

    func idToken() async throws -> String {
        return try await idTokenHandler?() ?? "mock_id_token"
    }

    func fcmToken() async throws -> String {
        return "mock_fcm_token"
    }
}
