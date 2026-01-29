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

        container.register(DailyQuestionLocalDataSourceProtocol.self) {
            DailyQuestionLocalDataSource(storage: container.resolve(SwiftDataStorage.self))
        }

        container.register(BalanceGameLocalDataSourceProtocol.self) {
            BalanceGameLocalDataSource(storage: container.resolve(SwiftDataStorage.self))
        }

        container.register(DailyQuestionRepositoryProtocol.self) {
            DailyQuestionRepository(
                networkProvider: container.resolve(NetworkProvider.self),
                tokenProvider: container.resolve(TokenProvider.self),
                firestoreService: container.resolve(FirestoreService.self),
                localDataSource: container.resolve(DailyQuestionLocalDataSourceProtocol.self)
            )
        }

        container.register(BalanceGameRepositoryProtocol.self) {
            BalanceGameRepository(
                networkProvider: container.resolve(NetworkProvider.self),
                tokenProvider: container.resolve(TokenProvider.self),
                firestoreService: container.resolve(FirestoreService.self),
                localDataSource: container.resolve(BalanceGameLocalDataSourceProtocol.self)
            )
            // 테스트를 위해 MockRepository
//          MockBalanceGameRepository()
        }

        container.register(HistoryRepositoryProtocol.self) {
            HistoryRepository(
                networkProvider: container.resolve(NetworkProvider.self),
                tokenProvider: container.resolve(TokenProvider.self)
            )
        }
    }
}
