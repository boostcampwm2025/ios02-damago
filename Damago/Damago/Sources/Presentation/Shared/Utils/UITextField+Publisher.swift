//
//  UITextField+Publisher.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import Combine
import UIKit

extension UITextField {
    var textPublisher: AnyPublisher<String, Never> {
        EventPublisher(control: self, event: .editingChanged)
            .map { [weak self] _ in self?.text ?? "" }
            .eraseToAnyPublisher()
    }
}
