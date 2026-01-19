//
//  RepositoryAssembly.swift
//  Damago
//
//  Created by 김재영 on 1/12/26.
//

import DamagoNetwork

final class RepositoryAssembly: Assembly {
    func assemble(_ container: any DIContainer) {
        container.register(UserRepositoryProtocol.self) {
            UserRepository(
                networkProvider: container.resolve(NetworkProvider.self),
                authService: container.resolve(AuthService.self),
                cryptoService: container.resolve(CryptoService.self),
                tokenProvider: container.resolve(TokenProvider.self),
                firestoreService: container.resolve(FirestoreService.self)
            )
        }
        
        container.register(PetRepositoryProtocol.self) {
            PetRepository(
                networkProvider: container.resolve(NetworkProvider.self),
                tokenProvider: container.resolve(TokenProvider.self),
                firestoreService: container.resolve(FirestoreService.self)
            )
        }
        
        container.register(PushRepositoryProtocol.self) {
            PushRepository(
                networkProvider: container.resolve(NetworkProvider.self),
                tokenProvider: container.resolve(TokenProvider.self)
            )
        }
        
        container.register(PokeShortcutRepositoryProtocol.self) {
            PokeShortcutRepository()
        }
    }
}
