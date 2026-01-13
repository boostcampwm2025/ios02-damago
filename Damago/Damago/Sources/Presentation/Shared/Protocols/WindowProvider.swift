//
//  WindowProvider.swift
//  Damago
//
//  Created by 박현수 on 1/13/26.
//

import UIKit

protocol WindowProvider {
    func provide() -> UIWindow
}

final class WindowProviderImpl: WindowProvider {
    func provide() -> UIWindow {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else { return UIWindow() }
        return window
    }
}
