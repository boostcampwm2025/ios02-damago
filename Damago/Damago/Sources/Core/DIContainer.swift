//
//  DIContainer.swift
//  Damago
//
//  Created by 박현수 on 1/12/26.
//

struct DependencyName: Hashable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        self.rawValue = value
    }
}

enum DependencyScope {
    case singleton
    case transient
}

protocol DIContainer: AnyObject {
    func register<T>(
        _ type: T.Type,
        name: DependencyName?,
        scope: DependencyScope,
        _ factory: @escaping () -> T
    )

    func resolve<T>(_ type: T.Type, name: DependencyName?) -> T
}

extension DIContainer {
    func register<T>(
        _ type: T.Type,
        name: DependencyName? = nil,
        scope: DependencyScope = .singleton,
        _ factory: @escaping () -> T
    ) {
        register(type, name: name, scope: scope, factory)
    }

    func resolve<T>(_ type: T.Type, name: DependencyName? = nil) -> T {
        resolve(type, name: name)
    }
}
