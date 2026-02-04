//
//  UserRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import Combine
import DamagoNetwork
import Foundation
import OSLog

enum DataMappingError: Error {
    case invalidDamagoType(String)
}

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
    
    func generateCode() async throws -> ConnectionCodes {
        let token = try await tokenProvider.idToken()
        let response: UserCodeDTO = try await networkProvider.request(UserAPI.generateCode(accessToken: token))
        return .init(myCode: response.myCode, partnerCode: response.partnerCode)
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
        return try response.toDomain()
    }
    
    func updateFCMToken(fcmToken: String?) async throws {
        guard let fcmToken = fcmToken ?? UserDefaults.standard.string(forKey: "fcmToken") else {
            SharedLogger.apns.error("fcm 토큰을 가져오지 못했습니다.")
            return
        }

        guard let idToken = try? await tokenProvider.idToken() else {
            SharedLogger.apns.log("fcm 토큰 업데이트 중 id token을 가져오지 못했습니다. 로그인 상태가 아닙니다.")
            return
        }

        try await networkProvider.requestSuccess(
            UserAPI.updateFCMToken(
                accessToken: idToken,
                fcmToken: fcmToken
            )
        )
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

    func observeCoupleSnapshot(coupleID: String) -> AnyPublisher<Result<CoupleSnapshotDTO, Error>, Never> {
        let firestorePath = FirestorePath.couples(coupleID: coupleID)
        
        let publisher: AnyPublisher<Result<CoupleSnapshotDTO, Error>, Never> =
        firestoreService.observe(collection: firestorePath.collection, document: firestorePath.document)
        
        return publisher
    }

    func observeUserSnapshot(uid: String) -> AnyPublisher<Result<UserSnapshotDTO, Error>, Never> {
        let firestorePath = FirestorePath.users(uid: uid)
        
        let publisher: AnyPublisher<Result<UserSnapshotDTO, Error>, Never> =
        firestoreService.observe(collection: firestorePath.collection, document: firestorePath.document)
        
        return publisher
    }

    func updateUserInfo(
        nickname: String?,
        anniversaryDate: Date?,
        useFCM: Bool?,
        useLiveActivity: Bool?,
        damagoName: String?,
        damagoType: DamagoType?
    ) async throws {
        let token = try await tokenProvider.idToken()
        let dateString = anniversaryDate.map {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.string(from: $0)
        }
        
        try await networkProvider.requestSuccess(
            UserAPI.updateUserInfo(
                accessToken: token,
                nickname: nickname,
                anniversaryDate: dateString,
                useFCM: useFCM,
                useLiveActivity: useLiveActivity,
                damagoName: damagoName,
                damagoType: damagoType?.rawValue
            )
        )
    }

    func signOut() throws {
        try authService.signOut()
    }

    func withdraw() async throws {
        let rawNonce = try cryptoService.randomNonceString()
        let hashedNonce = cryptoService.sha256(rawNonce)
        let credential = try await authService.request(hashedNonce: hashedNonce)

        let token = try await tokenProvider.idToken()

        try await networkProvider.requestSuccess(UserAPI.withdrawUser(accessToken: token))

        try await authService.deleteAccount(credential: credential)
    }
    
    func checkCoupleConnection() async throws -> Bool {
        let token = try await tokenProvider.idToken()
        let response: CheckCoupleConnectionResponse = try await networkProvider.request(
            UserAPI.checkCoupleConnection(accessToken: token)
        )
        return response.isConnected
    }
    
    func adjustCoin(amount: Int) async throws -> Int {
        let token = try await tokenProvider.idToken()
        let response: AdjustCoinResponse = try await networkProvider.request(
            UserAPI.adjustCoin(accessToken: token, amount: amount)
        )
        return response.totalCoin
    }
}

// MARK: - DTO Mapping
private extension UserInfoResponse {
    func toDomain() throws -> UserInfo {
        UserInfo(
            uid: uid,
            damagoID: damagoID,
            coupleID: coupleID,
            partnerUID: partnerUID,
            nickname: nickname,
            damagoStatus: try damagoStatus?.toDomain(),
            totalCoin: totalCoin ?? 0,
            lastFedAt: lastFedAt
        )
    }
}

extension DamagoStatusResponse {
    func toDomain() throws -> DamagoStatus {
        guard let damagoType = DamagoType(rawValue: damagoType) else {
            SharedLogger.common.error("invalid damagoType: \(damagoType)")
            throw DataMappingError.invalidDamagoType(damagoType)
        }
        
        return DamagoStatus(
            damagoName: damagoName,
            damagoType: damagoType,
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
