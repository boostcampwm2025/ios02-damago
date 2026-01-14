//
//  UserRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

protocol UserRepositoryProtocol {
    func generateCode(udid: String, fcmToken: String) async throws -> String
    func connectCouple(myCode: String, targetCode: String) async throws -> Bool
    func getUserInfo(udid: String) async throws -> UserInfo
    func signIn() async throws
}
