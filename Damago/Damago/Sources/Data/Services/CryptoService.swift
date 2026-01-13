//
//  CryptoService.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import CryptoKit
import Foundation

enum CryptoError: LocalizedError {
    case nonceGenerationDidFail(erorCode: Int32)
    case nonceNotExtists

    var errorDescription: String? {
        switch self {
        case let .nonceGenerationDidFail(erorCode):
            "nonce 생성(SecRandomCopyBytes)에 실패했습니다. OSStatus: \(erorCode)"
        case .nonceNotExtists:
            "로그인 콜백을 받았지만, nonce가 존재하지 않습니다."
        }
    }
}

protocol CryptoService {
    var currentNonceString: String? { get }
    func randomNonceString(length: Int) throws -> String
    func sha256(_ input: String) -> String
}

extension CryptoService {
    func randomNonceString() throws -> String {
        return try randomNonceString(length: 32)
    }
}

final class CryptoServiceImpl: CryptoService {
    var currentNonceString: String?

    func randomNonceString(length: Int) throws -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else { throw CryptoError.nonceGenerationDidFail(erorCode: errorCode) }

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in charset[Int(byte) % charset.count] }

        let nonceString = String(nonce)
        self.currentNonceString = nonceString
        return nonceString
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()

        return hashString
    }
}
