//
//  TextInputState.swift
//  Damago
//
//  Created by loyH on 2/3/26.
//

import UIKit

// 텍스트 입력 상태 저장 (maxLength/옵저버/카운터 UI)
final class TextInputState {
    var maxLength: Int?
    var observer: NSObjectProtocol?
    var textObservation: NSKeyValueObservation?
    var counterLabel: UILabel?
    var counterContainer: UIView?
}

// UITextField/UITextView별 상태 저장소
enum TextInputStateStore {
    private static let textFieldStore = NSMapTable<UITextField, TextInputState>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )
    private static let textViewStore = NSMapTable<UITextView, TextInputState>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )
    private static let lock = NSLock()

    static func state(for textField: UITextField) -> TextInputState {
        lock.lock()
        defer { lock.unlock() }
        if let state = textFieldStore.object(forKey: textField) { return state }
        let state = TextInputState()
        textFieldStore.setObject(state, forKey: textField)
        return state
    }

    static func state(for textView: UITextView) -> TextInputState {
        lock.lock()
        defer { lock.unlock() }
        if let state = textViewStore.object(forKey: textView) { return state }
        let state = TextInputState()
        textViewStore.setObject(state, forKey: textView)
        return state
    }
}

// 텍스트 입력 상태 접근 프로토콜
protocol TextInputStateStoring: AnyObject {
    var textInputState: TextInputState { get }
}
