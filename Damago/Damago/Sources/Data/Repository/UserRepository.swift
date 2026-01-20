//
//  UserRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import Combine
import DamagoNetwork

final class UserRepository: UserRepositoryProtocol {
    private let networkProvider: NetworkProvider
    private let authService: AuthService
    private let cryptoService: CryptoService
    private let tokenProvider: TokenProvider
    private let firestoreService: FirestoreService

    init(
        networkProvider: NetworkProvider,
        authService: AuthService,
        cryptoService: CryptoService,
        tokenProvider: TokenProvider,
        firestoreService: FirestoreService
    ) {
        self.networkProvider = networkProvider
        self.authService = authService
        self.cryptoService = cryptoService
        self.tokenProvider = tokenProvider
        self.firestoreService = firestoreService
    }
    
    func generateCode(fcmToken: String) async throws -> String {
        let token = try await tokenProvider.idToken()
        return try await networkProvider.requestString(UserAPI.generateCode(accessToken: token, fcmToken: fcmToken))
    }
    
    func connectCouple(targetCode: String) async throws {
        let token = try await tokenProvider.idToken()
        try await networkProvider.requestSuccess(
            UserAPI.connectCouple(
                accessToken: token,
                targetCode: targetCode
            )
        )
    }
    
    func getUserInfo() async throws -> UserInfo {
        let token = try await tokenProvider.idToken()
        let response: UserInfoResponse = try await networkProvider.request(UserAPI.getUserInfo(accessToken: token))
        return response.toDomain()
    }

    func signIn() async throws {
        let rawNonce = try cryptoService.randomNonceString()
        let hashedNonce = cryptoService.sha256(rawNonce)

        let requestResult = try await authService.request(hashedNonce: hashedNonce)
        try await authService.signIn(credential: requestResult, rawNonce: rawNonce)
    }

    func fcmToken() async throws -> String {
        try await tokenProvider.fcmToken()
    }

    func observeCoupleSharedInfo(coupleID: String) -> AnyPublisher<Result<CoupleSharedInfo, Error>, Never> {
        firestoreService.observe(collection: "couples", document: coupleID)
            .map { (result: Result<CoupleDTO, Error>) in
                switch result {
                case let .success(value):
                    return .success(value.toDomain())
                case let .failure(error):
                    return .failure(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - DTO Mapping
private extension UserInfoResponse {
    func toDomain() -> UserInfo {
        UserInfo(
            uid: uid,
            damagoID: damagoID,
            coupleID: coupleID,
            partnerUID: partnerUID,
            nickname: nickname,
            petStatus: petStatus?.toDomain(),
            totalCoin: totalCoin ?? 0,
            lastFedAt: lastFedAt
        )
    }
}


extension DamagoStatusResponse {
    func toDomain() -> PetStatus {
        PetStatus(
            petName: petName,
            petType: petType,
            level: level,
            currentExp: currentExp,
            maxExp: maxExp,
            isHungry: isHungry,
            statusMessage: statusMessage,
            lastFedAt: lastFedAt,
            totalPlayTime: totalPlayTime ?? 0,
            lastActiveAt: lastActiveAt
        )
    }
}
