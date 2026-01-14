//
//  TokenProvider.swift
//  Damago
//
//  Created by 박현수 on 1/14/26.
//

import FirebaseAuth
import Foundation

enum TokenProvidingError: LocalizedError {
    case userNotSignedIn

    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "유저가 로그인 상태가 아닙니다. 토큰을 가져올 수 없습니다."
        }
    }
}

protocol TokenProvider: Sendable {
    func provide() async throws -> String
}

final class TokenProviderImpl: TokenProvider {
    func provide() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw TokenProvidingError.userNotSignedIn
        }

        return try await currentUser.getIDToken(forcingRefresh: false)
    }
}
