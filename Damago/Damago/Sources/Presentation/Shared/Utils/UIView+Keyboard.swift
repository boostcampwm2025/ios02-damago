//
//  UIView+Keyboard.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import UIKit

private struct AssociatedKeys {
    static var keyboardShowObserver: UInt8 = 0
    static var keyboardHideObserver: UInt8 = 0
}

extension UIView {
    /// 키보드가 올라올 때 뷰를 조정하여 텍스트 필드가 키보드 위에 보이도록 합니다.
    /// - Parameters:
    ///   - constraint: 조정할 constraint (예: centerYAnchor의 constant)
    ///   - textFieldsGetter: 텍스트 필드 배열을 동적으로 반환하는 클로저
    ///   - padding: 키보드와 텍스트 필드 사이의 여유 공간 (기본값: 20pt)
    func adjustViewForKeyboard(
        constraint: NSLayoutConstraint,
        textFieldsGetter: @escaping () -> [UITextField],
        padding: CGFloat = 20
    ) {
        if let showObserver = objc_getAssociatedObject(self, &AssociatedKeys.keyboardShowObserver) as? NSObjectProtocol {
            NotificationCenter.default.removeObserver(showObserver)
        }
        if let hideObserver = objc_getAssociatedObject(self, &AssociatedKeys.keyboardHideObserver) as? NSObjectProtocol {
            NotificationCenter.default.removeObserver(hideObserver)
        }
        
        let showObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak constraint] notification in
            guard let self = self,
                  let constraint = constraint,
                  let keyboardFrame = notification.userInfo?[
                      UIResponder.keyboardFrameEndUserInfoKey
                  ] as? CGRect,
                  let animationDuration = notification.userInfo?[
                      UIResponder.keyboardAnimationDurationUserInfoKey
                  ] as? Double,
                  let animationCurve = notification.userInfo?[
                      UIResponder.keyboardAnimationCurveUserInfoKey
                  ] as? UInt else {
                return
            }

            let textFields = textFieldsGetter()
            guard textFields.contains(where: { $0.isFirstResponder }) else { return }
            
            let keyboardHeight = keyboardFrame.height
            let moveUp = keyboardHeight / 2
            constraint.constant = -moveUp
            
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: UIView.AnimationOptions(rawValue: animationCurve)
            ) {
                self.layoutIfNeeded()
            }
        }
        
        let hideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak constraint] notification in
            guard let self = self,
                  let constraint = constraint,
                  let animationDuration = notification.userInfo?[
                      UIResponder.keyboardAnimationDurationUserInfoKey
                  ] as? Double,
                  let animationCurve = notification.userInfo?[
                      UIResponder.keyboardAnimationCurveUserInfoKey
                  ] as? UInt else {
                return
            }
            
            constraint.constant = 0
            
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: UIView.AnimationOptions(rawValue: animationCurve)
            ) {
                self.layoutIfNeeded()
            }
        }
        
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.keyboardShowObserver,
            showObserver,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.keyboardHideObserver,
            hideObserver,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
    
    /// 화면 탭 시 키보드를 내립니다.
    /// 버튼과 텍스트필드는 원래 동작을 유지합니다.
    /// - Parameter additionalAction: 키보드가 없을 때 실행할 추가 동작 (location을 파라미터로 받음)
    func setupKeyboardDismissOnTap(
        additionalAction: ((CGPoint) -> Void)? = nil
    ) {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleKeyboardDismissTap(_:))
        )
        tapGesture.cancelsTouchesInView = false
        
        let delegate = KeyboardDismissGestureDelegate(additionalAction: additionalAction)
        tapGesture.delegate = delegate
        
        // delegate를 제스처에 연결하여 메모리 유지
        objc_setAssociatedObject(
            tapGesture,
            &AssociatedKeys.gestureDelegateKey,
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func handleKeyboardDismissTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // delegate에서 additionalAction 가져오기
        if let delegate = gesture.delegate as? KeyboardDismissGestureDelegate {
            // 키보드가 올라와 있는지 확인
            let isKeyboardVisible = isAnyTextFieldFirstResponder(in: self)
            
            // 키보드가 올라와 있으면 키보드만 내림
            if isKeyboardVisible {
                endEditing(true)
                return
            }
            
            // 키보드가 없을 때 추가 동작 실행
            delegate.additionalAction?(location)
        } else {
            // delegate가 없으면 키보드만 내림
            endEditing(true)
        }
    }
    
    /// 뷰 계층 내에 first responder인 텍스트필드가 있는지 확인
    private func isAnyTextFieldFirstResponder(in view: UIView) -> Bool {
        if (view is UITextField || view is UITextView), view.isFirstResponder {
            return true
        }
        
        return view.subviews.contains { isAnyTextFieldFirstResponder(in: $0) }
    }
}

// MARK: - Associated Keys Extension
private extension AssociatedKeys {
    static var gestureDelegateKey: UInt8 = 0
}

// MARK: - Keyboard Dismiss Gesture Delegate
private class KeyboardDismissGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    let additionalAction: ((CGPoint) -> Void)?
    
    init(additionalAction: ((CGPoint) -> Void)? = nil) {
        self.additionalAction = additionalAction
        super.init()
    }
    
    // 버튼이나 텍스트필드를 터치하면 제스처가 인식되지 않도록 함
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // touch.view부터 시작하여 상위 뷰 계층을 탐색
        var currentView: UIView? = touch.view
        while let view = currentView {
            // UIButton이나 UITextField를 찾으면 제스처를 받지 않음 (원래 동작 허용)
            if view is UIButton || view is UITextField || view is UITextView {
                return false
            }
            currentView = view.superview
        }
        
        return true
    }
}
