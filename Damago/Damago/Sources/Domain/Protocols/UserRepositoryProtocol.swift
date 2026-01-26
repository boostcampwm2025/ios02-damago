//
//  UserRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

import Combine
import Foundation

protocol UserRepositoryProtocol {
    func generateCode() async throws -> String
    func connectCouple(targetCode: String) async throws
    func getUserInfo() async throws -> UserInfo
    func updateFCMToken(fcmToken: String) async throws
    func signIn() async throws
    func fcmToken() async throws -> String
    func observeCoupleSnapshot(coupleID: String) -> AnyPublisher<Result<CoupleSnapshotDTO, Error>, Never>
    func observeUserSnapshot(uid: String) -> AnyPublisher<Result<UserSnapshotDTO, Error>, Never>
    func updateUserInfo(nickname: String?, anniversaryDate: Date?, useFCM: Bool?, useLiveActivity: Bool?) async throws
    func signOut() throws
    func withdraw() async throws
    func checkCoupleConnection() async throws -> Bool
}
