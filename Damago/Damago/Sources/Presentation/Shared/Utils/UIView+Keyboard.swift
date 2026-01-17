//
//  UIView+Keyboard.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import UIKit

extension UIView {
    /// 키보드가 올라올 때 뷰를 조정하여 텍스트 필드가 키보드 위에 보이도록 합니다.
    /// - Parameters:
    ///   - constraint: 조정할 constraint (예: centerYAnchor의 constant)
    ///   - textFields: 감지할 텍스트 필드 배열
    ///   - padding: 키보드와 텍스트 필드 사이의 여유 공간 (기본값: 20pt)
    func adjustViewForKeyboard(
        constraint: NSLayoutConstraint,
        textFields: [UITextField],
        padding: CGFloat = 20
    ) {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
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
            
            // 현재 포커스된 텍스트 필드 찾기
            guard let activeTextField = textFields.first(where: { $0.isFirstResponder }) else { return }
            
            // 텍스트 필드의 위치 계산
            let textFieldFrame = activeTextField.convert(activeTextField.bounds, to: self)
            let textFieldBottom = textFieldFrame.maxY
            
            // 키보드 프레임을 뷰의 좌표계로 변환
            guard let window = self.window else { return }
            let keyboardFrameInView = self.convert(keyboardFrame, from: window)
            let keyboardTop = keyboardFrameInView.minY
            
            // 텍스트 필드가 키보드 위에 보이도록 조정
            let targetY = keyboardTop - padding - textFieldFrame.height
            
            if textFieldBottom > keyboardTop - padding {
                let adjustment = textFieldBottom - targetY
                constraint.constant = -adjustment
                
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0,
                    options: UIView.AnimationOptions(rawValue: animationCurve)
                ) {
                    self.layoutIfNeeded()
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
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
