//
//  UITextField+TextInput.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import UIKit

extension UITextField: TextInputPublishing, TextInputLengthLimiting, TextInputStateStoring, TextInputTextObserving {
    var textInputState: TextInputState {
        TextInputStateStore.state(for: self)
    }

    static var textDidChangeNotificationName: Notification.Name {
        UITextField.textDidChangeNotification
    }

    func currentText() -> String? { text }
    func setText(_ text: String) { self.text = text }
    func didEnforceMaxLength(_ length: Int) {
        // 프로그램 변경 후 UIControl 이벤트 동기화
        sendActions(for: .editingChanged)
    }

    func updateCounterLabel(current: Int, max: Int) {
        // bounds 미준비 시 재시도
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
        if let label = textInputState.counterLabel { return label }
        let label = UILabel()
        label.font = font
        label.textColor = .textTertiary
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        textInputState.counterLabel = label
        return label
    }

    private var counterContainerView: UIView {
        if let view = textInputState.counterContainer { return view }
        let view = UIView()
        textInputState.counterContainer = view
        return view
    }

    func observeTextChanges(_ handler: @escaping () -> Void) {
        attachTextObservation(owner: self, keyPath: \.text, handler: handler)
    }
}
