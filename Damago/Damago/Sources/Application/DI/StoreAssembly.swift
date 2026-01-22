//
//  StoreAssembly.swift
//  Damago
//
//  Created by 박현수 on 1/19/26.
//

final class StoreAssembly: Assembly {
    func assemble(_ container: any DIContainer) {
        container.register(GlobalStoreProtocol.self) {
            GlobalStore(
                observeGlobalStateUseCase: container.resolve(ObserveGlobalStateUseCase.self)
            )
        }
    }
}
