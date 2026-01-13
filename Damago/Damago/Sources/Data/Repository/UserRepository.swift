//
//  UserRepository.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import DamagoNetwork

final class UserRepository: UserRepositoryProtocol {
    private let networkProvider: NetworkProvider
    
    init(networkProvider: NetworkProvider) {
        self.networkProvider = networkProvider
    }
    
    func generateCode(udid: String, fcmToken: String) async throws -> String {
        try await networkProvider.requestString(UserAPI.generateCode(udid: udid, fcmToken: fcmToken))
    }
    
    func connectCouple(myCode: String, targetCode: String) async throws -> Bool {
        try await networkProvider.requestSuccess(UserAPI.connectCouple(myCode: myCode, targetCode: targetCode))
    }
    
    func getUserInfo(udid: String) async throws -> UserInfo {
        let response: UserInfoResponse = try await networkProvider.request(UserAPI.getUserInfo(udid: udid))
        return response.toDomain()
    }
}

// MARK: - DTO Mapping
private extension UserInfoResponse {
    func toDomain() -> UserInfo {
        UserInfo(
            udid: udid,
            damagoID: damagoID,
            partnerUDID: partnerUDID,
            nickname: nickname,
            petStatus: petStatus?.toDomain(),
            totalCoin: totalCoin ?? 0,
            lastFedAt: lastFedAt
        )
    }
}

private extension DamagoStatusResponse {
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
            totalPlayTime: totalPlayTime,
            lastActiveAt: lastActiveAt
        )
    }
}