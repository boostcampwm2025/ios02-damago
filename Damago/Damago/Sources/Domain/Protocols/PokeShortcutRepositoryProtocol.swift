//
//  PokeShortcutRepositoryProtocol.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import Foundation

protocol PokeShortcutRepositoryProtocol {
    var shortcuts: [PokeShortcut] { get set }
    func updateShortcut(at index: Int, shortcut: PokeShortcut)
}
