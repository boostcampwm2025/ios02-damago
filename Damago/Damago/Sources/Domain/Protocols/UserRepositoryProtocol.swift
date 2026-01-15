//
//  UserRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

protocol UserRepositoryProtocol {
    func generateCode(fcmToken: String) async throws -> String
    func connectCouple(targetCode: String) async throws -> Bool
    func getUserInfo() async throws -> UserInfo
    func signIn() async throws
}
