//
//  PokeShortcutRepository.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import Foundation

final class PokeShortcutRepository: PokeShortcutRepositoryProtocol {
    private let userDefaults = AppGroupUserDefaults.sharedDefaults()
    private let shortcutsKey = "pokeShortcuts"
    
    init() {
        setupDefaultShortcutsIfNeeded()
    }
    
    var shortcuts: [PokeShortcut] {
        get {
            guard let data = userDefaults.data(
                forKey: AppGroupUserDefaults.shortcutsKey
            ),
                  let shortcuts = try? JSONDecoder().decode([PokeShortcut].self, from: data) else {
                return defaultShortcuts
            }
            return shortcuts
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: AppGroupUserDefaults.shortcutsKey)
            }
        }
    }
    
    func updateShortcut(at index: Int, shortcut: PokeShortcut) {
        var currentShortcuts = shortcuts
        guard index < currentShortcuts.count else { return }
        currentShortcuts[index] = shortcut
        shortcuts = currentShortcuts
    }
    
    private var defaultShortcuts: [PokeShortcut] {
        [
            PokeShortcut(summary: "안녕!", message: "안녕!"),
            PokeShortcut(summary: "밥 먹었어?", message: "밥 먹었어?"),
            PokeShortcut(summary: "머해?", message: "지금 머하구 있어?"),
            PokeShortcut(summary: "사랑해 💕", message: "사랑해 💕"),
            PokeShortcut(summary: "고마워!", message: "고마워!")
        ]
    }
    
    private func setupDefaultShortcutsIfNeeded() {
        if userDefaults.data(forKey: AppGroupUserDefaults.shortcutsKey) == nil {
            shortcuts = defaultShortcuts
        }
    }
}
