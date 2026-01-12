//
//  AppAssembly.swift
//  Damago
//
//  Created by 박현수 on 1/12/26.
//

final class AppAssembler {
    private let assemblies: [Assembly] = []

    func assemble(_ container: any DIContainer) {
        assemblies.forEach { $0.assemble(container) }
    }
}
