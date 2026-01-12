//
//  PetRepositoryProtocol.swift
//  Damago
//
//  Created by 김재영 on 1/13/26.
//

protocol PetRepositoryProtocol {
    func feed(damagoID: String) async throws -> Bool
}
