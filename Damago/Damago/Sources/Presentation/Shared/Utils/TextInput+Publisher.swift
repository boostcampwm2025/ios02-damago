//
//  TextInput+Publisher.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import Combine
import UIKit

protocol TextInputNotifying: AnyObject {
    static var textDidChangeNotificationName: Notification.Name { get }
    func currentText() -> String?
}

extension TextInputNotifying {
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(
            for: Self.textDidChangeNotificationName,
            object: self
        )
        .map { [weak self] _ in self?.currentText() ?? "" }
        .eraseToAnyPublisher()
    }

    var trimmedTextPublisher: AnyPublisher<String, Never> {
        textPublisher
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .eraseToAnyPublisher()
    }

    var nonEmptyTextPublisher: AnyPublisher<Bool, Never> {
        trimmedTextPublisher
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

extension UITextField: TextInputNotifying {
    static var textDidChangeNotificationName: Notification.Name {
        UITextField.textDidChangeNotification
    }

    func currentText() -> String? { text }
}

extension UITextView: TextInputNotifying {
    static var textDidChangeNotificationName: Notification.Name {
        UITextView.textDidChangeNotification
    }

    func currentText() -> String? { text }
}
