//
//  AuthService.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import AuthenticationServices
import FirebaseAuth

enum AuthError: LocalizedError {
    case identityTokenNotExists
    case tokenSerializationFailed

    var errorDescription: String? {
        switch self {
        case .identityTokenNotExists:
            return "identityToken이 존재하지 않습니다."
        case .tokenSerializationFailed:
            return "토큰 직렬화에 실패했습니다."
        }
    }
}

protocol AuthService {
    func request(hashedNonce: String) async throws -> AppleCredential
    func signIn(credential: AppleCredential, rawNonce: String) async throws
    func signOut() throws
}

final class AuthServiceImpl: NSObject, AuthService {
    private let windowProvider: WindowProvider

    private var requestContinuation: CheckedContinuation<AppleCredential, Error>?
    private var signInContinuation: CheckedContinuation<Bool, Error>?

    init(windowProvider: WindowProvider) {
        self.windowProvider = windowProvider
    }

    func request(hashedNonce: String) async throws -> AppleCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.requestContinuation = continuation
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    func signIn(credential: AppleCredential, rawNonce: String) async throws {
        let credential = OAuthProvider.appleCredential(
            withIDToken: credential.idToken,
            rawNonce: rawNonce,
            fullName: credential.fullName
        )

        let authResult = try await Auth.auth().signIn(with: credential)
    }

    func signOut() throws {
        let firebaseAuth = Auth.auth()
        try firebaseAuth.signOut()
    }
}

extension AuthServiceImpl: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { requestContinuation = nil }
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken
        else {
            requestContinuation?.resume(throwing: AuthError.identityTokenNotExists)
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            requestContinuation?.resume(throwing: AuthError.tokenSerializationFailed)
            return
        }
        requestContinuation?.resume(
            returning: AppleCredential(
                idToken: idTokenString,
                fullName: appleIDCredential.fullName
            )
        )
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        requestContinuation?.resume(throwing: error)
        requestContinuation = nil
    }
}

extension AuthServiceImpl: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        windowProvider.provide()
    }
}
