//
//  UIScrollView+Keyboard.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import UIKit
import Combine

extension UIScrollView {
    /// 키보드가 나타나거나 사라질 때 ContentInset을 자동으로 조정합니다.
    /// - Returns: Notification 구독을 관리하는 AnyCancellable (store(in:) 필요)
    func adjustContentInsetForKeyboard() -> AnyCancellable {
        let showPublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .sink { [weak self] keyboardFrame in
                guard let self = self else { return }
                // 키보드 높이만큼 하단 여백 추가
                let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
                self.contentInset = contentInset
                self.scrollIndicatorInsets = contentInset
            }
        
        let hidePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.contentInset = .zero
                self.scrollIndicatorInsets = .zero
            }
        
        return AnyCancellable {
            showPublisher.cancel()
            hidePublisher.cancel()
        }
    }
}
