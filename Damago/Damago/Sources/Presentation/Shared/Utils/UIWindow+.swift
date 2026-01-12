//
//  UIWindow+.swift
//  Damago
//
//  Created by 박현수 on 1/8/26.
//

import UIKit

extension UIWindow {
    func replaceRootViewController(with viewController: UIViewController) {
        self.rootViewController = viewController
        self.makeKeyAndVisible()
    }
}
