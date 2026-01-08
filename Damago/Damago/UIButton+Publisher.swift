//
//  UIButton+Publisher.swift
//  Damago
//
//  Created by 박현수 on 1/7/26.
//

import Combine
import UIKit

extension UIButton {
    var tapPublisher: AnyPublisher<Void, Never> {
        EventPublisher(control: self, event: .touchUpInside)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}
