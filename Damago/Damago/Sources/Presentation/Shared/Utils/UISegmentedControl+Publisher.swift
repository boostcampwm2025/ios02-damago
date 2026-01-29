//
//  UISegmentedControl+Publisher.swift
//  Damago
//
//  Created by 박현수 on 1/27/26.
//

import Combine
import UIKit

extension UISegmentedControl {
    var selectedSegmentIndexPublisher: AnyPublisher<Int, Never> {
        EventPublisher(control: self, event: .valueChanged)
            .map { control in
                (control as? UISegmentedControl)?.selectedSegmentIndex ?? 0
            }
            .eraseToAnyPublisher()
    }
}
