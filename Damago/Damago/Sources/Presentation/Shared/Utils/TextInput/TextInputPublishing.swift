//
//  TextInputPublishing.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import Combine
import UIKit

// UITextField/UITextView 텍스트 변경을 공통으로 퍼블리시
protocol TextInputPublishing: AnyObject {
    static var textDidChangeNotificationName: Notification.Name { get }
    func currentText() -> String?
}

extension UITextField: TextInputPublishing {
    static var textDidChangeNotificationName: Notification.Name {
        UITextField.textDidChangeNotification
    }
    
    func currentText() -> String? { text }
}

extension UITextView: TextInputPublishing {
    static var textDidChangeNotificationName: Notification.Name {
        UITextView.textDidChangeNotification
    }
    
    func currentText() -> String? { text }
}

extension TextInputPublishing {
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(
            for: Self.textDidChangeNotificationName,
            object: self
        )
        .map { [weak self] _ in self?.currentText() ?? "" }
        .eraseToAnyPublisher()
    }

    // 공백 제거된 문자열 퍼블리셔
    var trimmedTextPublisher: AnyPublisher<String, Never> {
        textPublisher
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .eraseToAnyPublisher()
    }

    // 비어있지 않은 상태 퍼블리셔
    var nonEmptyTextPublisher: AnyPublisher<Bool, Never> {
        trimmedTextPublisher
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
