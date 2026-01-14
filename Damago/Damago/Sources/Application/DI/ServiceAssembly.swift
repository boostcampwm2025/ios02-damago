//
//  ServiceAssembly.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import DamagoNetwork

final class ServiceAssembly: Assembly {
    func assemble(_ container: any DIContainer) {
        container.register(NetworkProvider.self) {
            NetworkProviderImpl()
        }
        container.register(WindowProvider.self) {
            WindowProviderImpl()
        }
        container.register(AuthService.self) {
            AuthServiceImpl(windowProvider: container.resolve(WindowProvider.self))
        }
        container.register(CryptoService.self) {
            CryptoServiceImpl()
        }
        container.register(TokenProvider.self) {
            TokenProviderImpl()
        }
    }
}
