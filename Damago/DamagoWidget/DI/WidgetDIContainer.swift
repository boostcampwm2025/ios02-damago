//
//  WidgetDIContainer.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import Foundation

final class WidgetDIContainer: DIContainer, @unchecked Sendable {
    static let shared = WidgetDIContainer()

    private init() { }

    private struct Key: Hashable {
        let type: ObjectIdentifier
        let name: DependencyName?
    }

    private struct Registration {
        let scope: DependencyScope
        let factory: () -> Any
    }

    private var registrations = [Key: Registration]()
    private var singletons = [Key: Any]()

    private let lock = NSRecursiveLock()

    func register<T>(
        _ type: T.Type,
        name: DependencyName? = nil,
        scope: DependencyScope = .singleton,
        _ factory: @escaping () -> T
    ) {
        lock.lock()
        defer { lock.unlock() }

        let key = Key(type: .init(type), name: name)
        registrations[key] = Registration(scope: scope, factory: factory)
    }

    func resolve<T>(_ type: T.Type, name: DependencyName? = nil) -> T {
        lock.lock()
        defer { lock.unlock() }

        let key = Key(type: .init(type), name: name)
        guard let registration = registrations[key] else { fatalError("\(type)에 대한 의존성이 등록되지 않았습니다.") }

        switch registration.scope {
        case .singleton:
            if let cached = singletons[key] as? T { return cached }
            guard let singleton = registration.factory() as? T else { fatalError("의존성 \(type) 생성 실패") }
            singletons[key] = singleton
            return singleton

        case .transient:
            guard let resolved = registration.factory() as? T else { fatalError("의존성 \(type) 생성 실패") }
            return resolved
        }
    }
}
