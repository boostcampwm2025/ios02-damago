//
//  WidgetAssembler.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

final class WidgetAssembler {
    private let assembleies: [Assembly] = [
        ServiceAssembly()
    ]

    func assemble(_ container: DIContainer) {
        assembleies.forEach { $0.assemble(container) }
    }
}
