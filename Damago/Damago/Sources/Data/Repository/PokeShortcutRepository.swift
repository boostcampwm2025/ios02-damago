//
//  PokeShortcutRepository.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import Foundation

final class PokeShortcutRepository: PokeShortcutRepositoryProtocol {
    private let userDefaults = UserDefaults.standard
    private let shortcutsKey = "pokeShortcuts"
    
    init() {
        setupDefaultShortcutsIfNeeded()
    }
    
    var shortcuts: [PokeShortcut] {
        get {
            guard let data = userDefaults.data(forKey: shortcutsKey),
                  let shortcuts = try? JSONDecoder().decode([PokeShortcut].self, from: data) else {
                return defaultShortcuts
            }
            return shortcuts
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: shortcutsKey)
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
            PokeShortcut(summary: "오늘 하루 어땠어?", message: "오늘 하루 어땠어?"),
            PokeShortcut(summary: "사랑해 💕", message: "사랑해 💕")
        ]
    }
    
    private func setupDefaultShortcutsIfNeeded() {
        if userDefaults.data(forKey: shortcutsKey) == nil {
            shortcuts = defaultShortcuts
        }
    }
}
