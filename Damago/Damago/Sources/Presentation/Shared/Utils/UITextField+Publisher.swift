//
//  UITextField+Publisher.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import Combine
import UIKit

private var maxLengthKey: UInt8 = 0

extension UITextField {
    var textPublisher: AnyPublisher<String, Never> {
        EventPublisher(control: self, event: .editingChanged)
            .map { [weak self] _ in self?.text ?? "" }
            .eraseToAnyPublisher()
    }
    
    /// 텍스트 필드의 최대 입력 길이를 설정합니다.
    /// nil이면 길이 제한이 없습니다.
    var maxLength: Int? {
        get {
            return objc_getAssociatedObject(self, &maxLengthKey) as? Int
        }
        set {
            objc_setAssociatedObject(
                self,
                &maxLengthKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
