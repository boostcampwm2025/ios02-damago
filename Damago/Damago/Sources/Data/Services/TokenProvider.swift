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
    case fcmTokenNotExists
    case invalidRefreshToken

    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "유저가 로그인 상태가 아닙니다. 토큰을 가져올 수 없습니다."
        case .fcmTokenNotExists:
            return "FCM 토큰을 가져올 수 없습니다."
        case .invalidRefreshToken:
            return "세션이 만료되었습니다. 다시 로그인해 주세요."
        }
    }
}

protocol TokenProvider: Sendable {
    func idToken() async throws -> String
    func fcmToken() async throws -> String
}

final class TokenProviderImpl: TokenProvider {
    nonisolated init() { }

    func idToken() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw TokenProvidingError.userNotSignedIn
        }

        do {
            return try await currentUser.getIDToken(forcingRefresh: false)
        } catch {
            if Self.isInvalidRefreshTokenError(error) {
                try? Auth.auth().signOut()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .authenticationStateDidChange, object: nil)
                }
                throw TokenProvidingError.invalidRefreshToken
            }
            throw error
        }
    }

    /// Firebase `INVALID_REFRESH_TOKEN` (또는 내부 에러 17999에 포함된 경우) 감지
    private static func isInvalidRefreshTokenError(_ error: Error) -> Bool {
        var e: Error? = error
        while let err = e {
            let ne = err as NSError
            if let resp = ne.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] as? [String: Any],
               (resp["message"] as? String) == "INVALID_REFRESH_TOKEN" {
                return true
            }
            e = ne.userInfo[NSUnderlyingErrorKey] as? Error
        }
        return false
    }

    func fcmToken() async throws -> String {
        if let token = UserDefaults.standard.string(forKey: "fcmToken") { return token }

        // 알림이 올 때까지 기다림 (첫 번째 알림만 받고 끝냄)
        _ = await NotificationCenter.default.notifications(named: .fcmTokenDidUpdate).first { _ in true }

        guard let token = UserDefaults.standard.string(forKey: "fcmToken") else {
            throw TokenProvidingError.fcmTokenNotExists
        }
        return token
    }
}
