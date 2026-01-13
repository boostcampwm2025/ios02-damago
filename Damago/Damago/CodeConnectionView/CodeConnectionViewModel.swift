//
//  CodeConnectionViewModel.swift
//  Damago
//
//  Created by Eden Landelyse on 12/17/25.
//

import Foundation
import UIKit

final class CodeConnectionViewModel {
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
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
            let success = try await userRepository.connectCouple(myCode: code, targetCode: targetCode)
            await MainActor.run { [weak self] in self?.onConnected?(success) }
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
        guard let udid = udid else { return nil }
        return try await userRepository.generateCode(udid: udid, fcmToken: fcmToken)
    }
}
