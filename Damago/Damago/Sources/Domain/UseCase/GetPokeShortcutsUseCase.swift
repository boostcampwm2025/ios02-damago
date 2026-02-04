//
//  GetPokeShortcutsUseCase.swift
//  Damago
//
//  Created by 박현수 on 2/3/26.
//

import Foundation

protocol GetPokeShortcutsUseCase {
    func execute() -> [PokeShortcut]
}

final class GetPokeShortcutsUseCaseImpl: GetPokeShortcutsUseCase {
    private let repository: PokeShortcutRepositoryProtocol

    init(repository: PokeShortcutRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> [PokeShortcut] {
        repository.shortcuts
    }
}
