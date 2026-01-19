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
    func setupKeyboardDismissOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func dismissKeyboard() {
        endEditing(true)
    }
}
