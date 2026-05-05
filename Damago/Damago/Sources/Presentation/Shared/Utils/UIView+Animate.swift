//
//  UIView+Animate.swift
//  Damago
//
//  Created by 김재영 on 2/6/26.
//

import UIKit

extension UIView {
    static func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void) async {
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration, animations: animations) { _ in
                continuation.resume()
            }
        }
    }
}
