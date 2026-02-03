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
private var textInputCounterLabelKey: UInt8 = 0
private var textInputCounterContainerKey: UInt8 = 0

protocol TextInputPublishing: AnyObject {
    static var textDidChangeNotificationName: Notification.Name { get }
    func currentText() -> String?
}

protocol TextInputLengthLimiting: AnyObject {
    func setText(_ text: String)
    func didEnforceMaxLength(_ length: Int)
    func updateCounterLabel(current: Int, max: Int)
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
                updateCounterLabelIfNeeded()
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
            self?.updateCounterLabelIfNeeded()
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

    private func updateCounterLabelIfNeeded() {
        guard let maxLength, maxLength >= 0 else { return }
        let current = currentText()?.count ?? 0
        updateCounterLabel(current: current, max: maxLength)
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

    func updateCounterLabel(current: Int, max: Int) {
        if bounds.height == 0 {
            DispatchQueue.main.async { [weak self] in
                self?.updateCounterLabel(current: current, max: max)
            }
            return
        }
        let label = counterLabel
        label.text = "\(current) / \(max)"
        let container = counterContainerView
        let size = label.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height)
        )
        let width = size.width + (.spacingS * 2)
        let height = bounds.height
        container.frame = CGRect(x: 0, y: 0, width: width, height: height)
        label.frame = CGRect(
            x: .spacingS,
            y: (height - size.height) / 2,
            width: size.width,
            height: size.height
        )
        if label.superview == nil {
            container.addSubview(label)
        }
        if rightView !== container {
            rightView = container
            rightViewMode = .always
        }
    }

    private var counterLabel: UILabel {
        if let label = objc_getAssociatedObject(self, &textInputCounterLabelKey) as? UILabel {
            return label
        }
        let label = UILabel()
        label.font = font
        label.textColor = .textTertiary
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        objc_setAssociatedObject(
            self,
            &textInputCounterLabelKey,
            label,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return label
    }

    private var counterContainerView: UIView {
        if let view = objc_getAssociatedObject(self, &textInputCounterContainerKey) as? UIView {
            return view
        }
        let view = UIView()
        objc_setAssociatedObject(
            self,
            &textInputCounterContainerKey,
            view,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return view
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

    func updateCounterLabel(current: Int, max: Int) {
        let label = counterLabel
        label.text = "\(current) / \(max)"
        guard let parent = superview else {
            DispatchQueue.main.async { [weak self] in
                self?.updateCounterLabel(current: current, max: max)
            }
            return
        }
        if label.superview == nil {
            parent.addSubview(label)
            NSLayoutConstraint.activate([
                label.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -.spacingM),
                label.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -.spacingM)
            ])
        }
        parent.bringSubviewToFront(label)
    }

    private var counterLabel: UILabel {
        if let label = objc_getAssociatedObject(self, &textInputCounterLabelKey) as? UILabel {
            return label
        }
        
        let label = UILabel()
        label.font = .caption
        label.textColor = .textTertiary
        label.textAlignment = .right
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        objc_setAssociatedObject(
            self,
            &textInputCounterLabelKey,
            label,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return label
    }
}
