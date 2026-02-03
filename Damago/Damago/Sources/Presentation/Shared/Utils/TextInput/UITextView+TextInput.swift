//
//  UITextView+TextInput.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import UIKit

extension UITextView: TextInputPublishing, TextInputLengthLimiting, TextInputStateStoring, TextInputTextObserving {
    var textInputState: TextInputState {
        TextInputStateStore.state(for: self)
    }

    static var textDidChangeNotificationName: Notification.Name {
        UITextView.textDidChangeNotification
    }

    func currentText() -> String? { text }
    func setText(_ text: String) { self.text = text }
    func didEnforceMaxLength(_ length: Int) {
        // 잘라낸 뒤 커서를 끝으로 이동
        selectedRange = NSRange(location: length, length: 0)
    }

    func updateCounterLabel(current: Int, max: Int) {
        let label = counterLabel
        label.text = "\(current) / \(max)"
        guard let parent = superview else {
            // 뷰 계층이 준비될 때까지 대기
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
        if let label = textInputState.counterLabel { return label }
        let label = UILabel()
        label.font = .caption
        label.textColor = .textTertiary
        label.textAlignment = .right
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        textInputState.counterLabel = label
        return label
    }

    func observeTextChanges(_ handler: @escaping () -> Void) {
        attachTextObservation(owner: self, keyPath: \.text, handler: handler)
    }
}
