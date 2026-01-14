//
//  DataAssembly.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import DamagoNetwork

final class DataAssembly: Assembly {
    func assemble(_ container: any DIContainer) {
        let networkProvider = NetworkProvider()
        
        container.register(UserRepositoryProtocol.self) {
            UserRepository(networkProvider: networkProvider)
        }
        
        container.register(PetRepositoryProtocol.self) {
            PetRepository(networkProvider: networkProvider)
        }
        
        container.register(PushRepositoryProtocol.self) {
            PushRepository(networkProvider: networkProvider)
        }
        
        container.register(PokeShortcutRepositoryProtocol.self) {
            PokeShortcutRepository()
        }
    }
}
