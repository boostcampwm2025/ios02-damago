//
//  UIDatePicker+Publisher.swift
//  Damago
//
//  Created by 박현수 on 1/22/26.
//

import Combine
import UIKit

extension UIDatePicker {
    var datePublisher: AnyPublisher<Date, Never> {
        EventPublisher(control: self, event: .valueChanged)
            .map { [weak self] _ in self?.date ?? Date() }
            .eraseToAnyPublisher()
    }
}
