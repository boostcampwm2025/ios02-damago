//
//  CardGameModels.swift
//  Damago
//
//  Created by 박현수 on 2026/01/28.
//

import Foundation

enum CardGameDifficulty {
    case easy
    case hard

    var cardCount: Int {
        switch self {
        case .easy: return 8
        case .hard: return 16
        }
    }

    var rows: Int {
        4
    }

    var columns: Int {
        switch self {
        case .easy: return 2
        case .hard: return 4
        }
    }
}

nonisolated enum CardMatchingState: Equatable {
    case none
    case match
    case mismatch
}

nonisolated struct CardItem: Hashable, Identifiable {
    let id: UUID
    let image: Data?
    var isFlipped: Bool
    var isMatched: Bool
    var matchingState: CardMatchingState = .none
}

enum CardGameSection: Int, CaseIterable {
    case main
}
