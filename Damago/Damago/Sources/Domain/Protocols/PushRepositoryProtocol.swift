//
//  PushRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

protocol PushRepositoryProtocol {
    func poke(udid: String) async throws -> Bool
    func saveLiveActivityToken(udid: String, startToken: String?, updateToken: String?) async throws -> Bool
}
