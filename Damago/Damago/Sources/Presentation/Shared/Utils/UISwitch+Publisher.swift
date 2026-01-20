//
//  UISwitch+Publisher.swift
//  Damago
//
//  Created by 박현수 on 1/20/26.
//

import Combine
import UIKit

extension UISwitch {
    var valueChangedPublisher: AnyPublisher<Bool, Never> {
        EventPublisher(control: self, event: .valueChanged)
            .map { ($0 as? UISwitch)?.isOn ?? false }
            .eraseToAnyPublisher()
    }
}
