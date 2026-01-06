//
//  CodeConnectionViewModel.swift
//  Damago
//
//  Created by Eden Landelyse on 12/17/25.
//

import Foundation
import UIKit

final class CodeConnectionViewModel {
    var code: String = ""
    var onConnected: ((Bool) -> Void)?

    func resolveMyCode() async throws -> String? {
        guard let fcmToken = await waitForFCMToken(), // FCM 토큰 가져오기
              let newCode = try await requestGenerateCode(fcmToken: fcmToken) // API 호출하여 코드 생성
        else { return nil }
        self.code = newCode
        return newCode
    }

    func connectCouple(targetCode: String) async throws {
        do {
            try await requestConnectCouple(targetCode: targetCode)
            await MainActor.run { [weak self] in self?.onConnected?(true) }
        } catch {
            await MainActor.run { [weak self] in self?.onConnected?(false) }
        }
    }
}

// MARK: - 코드 생성

extension CodeConnectionViewModel {
    var udid: String? { UIDevice.current.identifierForVendor?.uuidString }

    private func waitForFCMToken() async -> String? {
        // 이미 있으면 반환
        if let token = UserDefaults.standard.string(forKey: "fcmToken") { return token }

        // 알림이 올 때까지 기다림 (첫 번째 알림만 받고 끝냄)
        _ = await NotificationCenter.default.notifications(named: .fcmTokenDidUpdate).first { _ in true }

        return UserDefaults.standard.string(forKey: "fcmToken")
    }

    private func requestGenerateCode(fcmToken: String) async throws -> String? {
        guard let url = URL(string: "\(BaseURL.string)/generate_code"),
              let udid = udid
        else { return nil }

        var request = URLRequest(url: url)
        let body = ["udid": udid, "fcmToken": fcmToken]

        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidStatusCode(
                httpResponse.statusCode,
                String(data: data, encoding: .utf8) ?? "invalid data"
            )
        }

        return String(data: data, encoding: .utf8)
    }
}

// MARK: - 커플 연결

extension CodeConnectionViewModel {
    private func requestConnectCouple(targetCode: String) async throws {
        guard let url = URL(string: "\(BaseURL.string)/connect_couple") else { return }

        var request = URLRequest(url: url)
        let body = ["myCode": code, "targetCode": targetCode]

        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidStatusCode(
                httpResponse.statusCode,
                String(data: data, encoding: .utf8) ?? "invalid data"
            )
        }
    }
}

enum NetworkError: Error {
    case invalidStatusCode(Int, String)
    case invalidResponse
}
