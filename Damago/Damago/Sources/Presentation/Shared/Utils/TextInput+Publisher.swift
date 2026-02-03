//
//  TextInput+Publisher.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import Combine
import UIKit

private var textInputMaxLengthKey: UInt8 = 0
private var textInputObserverTokenKey: UInt8 = 0

protocol TextInputPublishing: AnyObject {
    static var textDidChangeNotificationName: Notification.Name { get }
    func currentText() -> String?
}

protocol TextInputLengthLimiting: AnyObject {
    func setText(_ text: String)
    func didEnforceMaxLength(_ length: Int)
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

extension TextInputPublishing where Self: NSObject & TextInputLengthLimiting {
    /// 텍스트 입력의 최대 길이를 설정합니다.
    /// nil이면 길이 제한이 없습니다.
    var maxLength: Int? {
        get {
            objc_getAssociatedObject(self, &textInputMaxLengthKey) as? Int
        }
        set {
            objc_setAssociatedObject(
                self,
                &textInputMaxLengthKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )

            if newValue == nil {
                removeMaxLengthObserverIfNeeded()
            } else {
                registerMaxLengthObserverIfNeeded()
                enforceMaxLengthIfNeeded()
            }
        }
    }

    private func registerMaxLengthObserverIfNeeded() {
        guard maxLengthObserverToken == nil else { return }
        let token = NotificationCenter.default.addObserver(
            forName: Self.textDidChangeNotificationName,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.enforceMaxLengthIfNeeded()
        }
        maxLengthObserverToken = token
    }

    private func removeMaxLengthObserverIfNeeded() {
        guard let token = maxLengthObserverToken else { return }
        NotificationCenter.default.removeObserver(token)
        maxLengthObserverToken = nil
    }

    private var maxLengthObserverToken: NSObjectProtocol? {
        get { objc_getAssociatedObject(self, &textInputObserverTokenKey) as? NSObjectProtocol }
        set {
            objc_setAssociatedObject(
                self,
                &textInputObserverTokenKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private func enforceMaxLengthIfNeeded() {
        guard let maxLength, maxLength >= 0 else { return }
        guard let text = currentText(), text.count > maxLength else { return }
        let limited = String(text.prefix(maxLength))
        setText(limited)
        didEnforceMaxLength(limited.count)
    }
}

extension UITextField: TextInputPublishing, TextInputLengthLimiting {
    static var textDidChangeNotificationName: Notification.Name {
        UITextField.textDidChangeNotification
    }

    func currentText() -> String? { text }
    func setText(_ text: String) { self.text = text }
    func didEnforceMaxLength(_ length: Int) {
        sendActions(for: .editingChanged)
    }
}

extension UITextView: TextInputPublishing, TextInputLengthLimiting {
    static var textDidChangeNotificationName: Notification.Name {
        UITextView.textDidChangeNotification
    }

    func currentText() -> String? { text }
    func setText(_ text: String) { self.text = text }
    func didEnforceMaxLength(_ length: Int) {
        selectedRange = NSRange(location: length, length: 0)
    }
}
