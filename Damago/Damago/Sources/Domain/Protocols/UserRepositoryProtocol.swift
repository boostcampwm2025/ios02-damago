//
//  UserRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

import Combine

protocol UserRepositoryProtocol {
    func generateCode(fcmToken: String) async throws -> String
    func connectCouple(targetCode: String) async throws
    func getUserInfo() async throws -> UserInfo
    func signIn() async throws
    func fcmToken() async throws -> String
    func observeCoupleSharedInfo(coupleID: String) -> AnyPublisher<Result<CoupleSharedInfo, Error>, Never>
    func signOut() throws
}
