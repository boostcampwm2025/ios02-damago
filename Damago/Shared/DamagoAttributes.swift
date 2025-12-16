//
//  DamagoAttributes.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit

struct DamagoAttributes: ActivityAttributes {
    // MARK: - Dynamic State
    public struct ContentState: Codable, Hashable {
        var petImageName: String
        var statusImageName: String
    }

    // MARK: - Static Data
    var petName: String
}
