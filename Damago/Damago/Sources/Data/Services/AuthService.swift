//
//  AuthService.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import AuthenticationServices
import FirebaseAuth

enum AuthError: LocalizedError {
    case identityTokennotExists
    case tokenSerializationFailed

    var errorDescription: String? {
        switch self {
        case .identityTokennotExists:
            return "identityToken이 존재하지 않습니다."
        case .tokenSerializationFailed:
            return "토큰 직렬화에 실패했습니다."
        }
    }
}

protocol AuthService {
    func request() async throws -> AppleCredential
    func signIn(with credential: AppleCredential) async throws
}

final class AuthServiceImpl: NSObject, AuthService {
    private let windowProvider: WindowProvider
    private let cryptoService: CryptoService

    private var requestContinuation: CheckedContinuation<AppleCredential, Error>?
    private var signInContinuation: CheckedContinuation<Bool, Error>?

    init(windowProvider: WindowProvider, cryptoService: CryptoService) {
        self.windowProvider = windowProvider
        self.cryptoService = cryptoService
    }

    func request() async throws -> AppleCredential {
        let nonce = try cryptoService.randomNonceString()

        return try await withCheckedThrowingContinuation { continuation in
            self.requestContinuation = continuation
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = cryptoService.sha256(nonce)
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    func signIn(with credential: AppleCredential) async throws {
        let credential = OAuthProvider.appleCredential(
            withIDToken: credential.idToken,
            rawNonce: credential.nonce,
            fullName: credential.fullName
        )


        let authResult = try await Auth.auth().signIn(with: credential)
    }
}

extension AuthServiceImpl: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { requestContinuation = nil }
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        guard let nonce = cryptoService.currentNonceString else {
            requestContinuation?.resume(throwing: CryptoError.nonceNotExtists)
            return
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            requestContinuation?.resume(throwing: AuthError.identityTokennotExists)
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            requestContinuation?.resume(throwing: AuthError.tokenSerializationFailed)
            return
        }
        requestContinuation?.resume(
            returning: AppleCredential(
                idToken: idTokenString,
                nonce: nonce,
                fullName: appleIDCredential.fullName
            )
        )
        return
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        requestContinuation?.resume(throwing: error)
        requestContinuation = nil
    }
}

extension AuthServiceImpl: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return windowProvider.provide()
    }
}
