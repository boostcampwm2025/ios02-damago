//
//  TextInputMaxLength.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import UIKit

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

// text 변경
func attachTextObservation<T: NSObject & TextInputStateStoring>(
    owner: T,
    keyPath: KeyPath<T, String?>,
    handler: @escaping () -> Void
) {
    // programmatic 변경(텍스트 할당)도 카운터 갱신 대상
    owner.textInputState.textObservation = owner.observe(keyPath, options: [.new]) { _, _ in
        handler()
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
        textInputState.textObservation = nil
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
