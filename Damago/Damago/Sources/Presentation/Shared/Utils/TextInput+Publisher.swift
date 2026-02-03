//
//  TextInput+Publisher.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import Combine
import UIKit

// 텍스트 입력 상태 저장 (maxLength/옵저버/카운터 UI)
final class TextInputState {
    var maxLength: Int?
    var observer: NSObjectProtocol?
    var textObservation: NSKeyValueObservation?
    var counterLabel: UILabel?
    var counterContainer: UIView?
}

// 텍스트 입력 상태 접근 프로토콜
protocol TextInputStateStoring: AnyObject {
    var textInputState: TextInputState { get }
}

// UITextField/UITextView별 상태 저장소
private enum TextInputStateStore {
    private static let textFieldStore = NSMapTable<UITextField, TextInputState>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )
    private static let textViewStore = NSMapTable<UITextView, TextInputState>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )

    static func state(for textField: UITextField) -> TextInputState {
        if let state = textFieldStore.object(forKey: textField) { return state }
        let state = TextInputState()
        textFieldStore.setObject(state, forKey: textField)
        return state
    }

    static func state(for textView: UITextView) -> TextInputState {
        if let state = textViewStore.object(forKey: textView) { return state }
        let state = TextInputState()
        textViewStore.setObject(state, forKey: textView)
        return state
    }
}

// UITextField/UITextView 텍스트 변경을 공통으로 퍼블리시
protocol TextInputPublishing: AnyObject {
    static var textDidChangeNotificationName: Notification.Name { get }
    func currentText() -> String?
}

// 최대 길이 제한 + 카운터 라벨 지원
protocol TextInputLengthLimiting: AnyObject {
    func setText(_ text: String)
    func didEnforceMaxLength(_ length: Int)
    func updateCounterLabel(current: Int, max: Int)
}

// programmatic 텍스트 변경 감지
protocol TextInputTextObserving: AnyObject {
    func observeTextChanges(_ handler: @escaping () -> Void)
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

extension TextInputPublishing where Self: NSObject & TextInputLengthLimiting & TextInputStateStoring & TextInputTextObserving {
    // 입력 최대 길이. `nil`이면 제한 없음
    var maxLength: Int? {
        get {
            textInputState.maxLength
        }
        set {
            textInputState.maxLength = newValue

            if newValue == nil {
                removeMaxLengthObserverIfNeeded()
            } else {
                registerMaxLengthObserverIfNeeded()
                enforceMaxLengthIfNeeded()
                updateCounterLabelIfNeeded()
            }
        }
    }

    // 변경 알림은 1회만 등록
    private func registerMaxLengthObserverIfNeeded() {
        guard maxLengthObserverToken == nil else { return }
        if textInputState.textObservation == nil {
            observeTextChanges { [weak self] in
                self?.enforceMaxLengthIfNeeded()
                self?.updateCounterLabelIfNeeded()
            }
        }
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

    // maxLength 해제 시 옵저버 제거
    private func removeMaxLengthObserverIfNeeded() {
        guard let token = maxLengthObserverToken else { return }
        NotificationCenter.default.removeObserver(token)
        maxLengthObserverToken = nil
    }

    private var maxLengthObserverToken: NSObjectProtocol? {
        get { textInputState.observer }
        set { textInputState.observer = newValue }
    }

    // 길이 초과 시 잘라내기
    private func enforceMaxLengthIfNeeded() {
        guard let maxLength, maxLength >= 0 else { return }
        guard let text = currentText(), text.count > maxLength else { return }
        let limited = String(text.prefix(maxLength))
        setText(limited)
        didEnforceMaxLength(limited.count)
    }

    // 카운터 라벨 갱신
    private func updateCounterLabelIfNeeded() {
        guard let maxLength, maxLength >= 0 else { return }
        let current = currentText()?.count ?? 0
        updateCounterLabel(current: current, max: maxLength)
    }
}

extension UITextField: TextInputPublishing, TextInputLengthLimiting, TextInputStateStoring {
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
}

extension UITextField: TextInputTextObserving {
    func observeTextChanges(_ handler: @escaping () -> Void) {
        textInputState.textObservation = observe(\.text, options: [.new]) { _, _ in
            handler()
        }
    }
}

extension UITextView: TextInputPublishing, TextInputLengthLimiting, TextInputStateStoring {
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
}

extension UITextView: TextInputTextObserving {
    func observeTextChanges(_ handler: @escaping () -> Void) {
        textInputState.textObservation = observe(\.text, options: [.new]) { _, _ in
            handler()
        }
    }
}
