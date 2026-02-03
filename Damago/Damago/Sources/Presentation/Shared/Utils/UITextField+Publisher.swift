//
//  UITextField+Publisher.swift
//  Damago
//
//  Created by loyH on 1/14/26.
//

import UIKit

private var maxLengthKey: UInt8 = 0

extension UITextField {
    /// 텍스트 필드의 최대 입력 길이를 설정합니다.
    /// nil이면 길이 제한이 없습니다.
    var maxLength: Int? {
        get {
            objc_getAssociatedObject(self, &maxLengthKey) as? Int
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
