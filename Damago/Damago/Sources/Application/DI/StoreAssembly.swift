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
                observePetStatusUseCase: container.resolve(ObservePetStatusUseCase.self),
                observeCoupleSharedInfoUseCase: container.resolve(ObserveCoupleSharedInfoUseCase.self)
            )
        }
    }
}
