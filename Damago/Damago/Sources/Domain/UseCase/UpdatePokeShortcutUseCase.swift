//
//  UpdatePokeShortcutUseCase.swift
//  Damago
//
//  Created by 박현수 on 2/3/26.
//

import Foundation

protocol UpdatePokeShortcutUseCase {
    func execute(at index: Int, shortcut: PokeShortcut)
}

final class UpdatePokeShortcutUseCaseImpl: UpdatePokeShortcutUseCase {
    private let repository: PokeShortcutRepositoryProtocol

    init(repository: PokeShortcutRepositoryProtocol) {
        self.repository = repository
    }

    func execute(at index: Int, shortcut: PokeShortcut) {
        repository.updateShortcut(at: index, shortcut: shortcut)
    }
}
