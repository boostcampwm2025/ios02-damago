//
//  CodeConnectionViewModel.swift
//  Damago
//
//  Created by Eden Landelyse on 12/17/25.
//

import Foundation
import UIKit

final class CodeConnectionViewModel {
    var udid: String? { UIDevice.current.identifierForVendor?.uuidString }
    private let code: String = "exapleCode_123"
    var onConnected: (() -> Void)?

    func connectCouple(pairCode: String) async throws {
        // 입력받은 코드를 통해 cloud functions에 연결 요청
        // 연결 성공 시 home 화면으로 이동
        await MainActor.run { [weak self] in
            self?.onConnected?()
        }
    }

    func resolveMyCode() async throws -> String? {
        guard let fcmToken = await waitForFCMToken(), // FCM 토큰 가져오기
              let newCode = try await requestGenerateCode(fcmToken: fcmToken) // API 호출하여 코드 생성
        else { return nil }

        return newCode
    }
}

extension CodeConnectionViewModel {
    private func waitForFCMToken() async -> String? {
        // 이미 있으면 반환
        if let token = UserDefaults.standard.string(forKey: "fcmToken") { return token }

        // 알림이 올 때까지 기다림 (첫 번째 알림만 받고 끝냄)
        _ = await NotificationCenter.default.notifications(named: .fcmTokenDidUpdate).first { _ in true }

        return nil
    }

    private func requestGenerateCode(fcmToken: String) async throws -> String? {
        guard let url = URL(string: "https://generate-code-wrjwddcv2q-uc.a.run.app"),
              let udid = udid
        else { return nil }

        var request = URLRequest(url: url)
        let body = ["udid": udid, "fcmToken": fcmToken]

        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode)
        else { return nil }

        return String(data: data, encoding: .utf8)
    }
}
