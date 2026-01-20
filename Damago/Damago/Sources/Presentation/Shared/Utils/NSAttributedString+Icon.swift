//
//  NSAttributedString+Icon.swift
//  Damago
//
//  Created by 김재영 on 1/19/26.
//

import UIKit

extension NSAttributedString {
    /// 시스템 심볼 이미지와 텍스트를 조합하여 NSAttributedString을 반환합니다.
    /// - Parameters:
    ///   - systemName: SFSymbol 이름
    ///   - text: 뒤에 붙을 텍스트
    ///   - color: 아이콘과 텍스트의 색상
    ///   - font: 폰트
    /// - Returns: 아이콘과 텍스트가 결합된 NSAttributedString
    static func iconWithText(
        systemName: String,
        text: String,
        iconColor: UIColor,
        textColor: UIColor = .label,
        font: UIFont
    ) -> NSAttributedString {
        let config = UIImage.SymbolConfiguration(font: font)
        guard let image = UIImage(systemName: systemName, withConfiguration: config)?
            .withTintColor(iconColor, renderingMode: .alwaysOriginal) else {
            return NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: textColor
            ])
        }
        
        let attachment = NSTextAttachment()
        attachment.image = image
        
        let completeText = NSMutableAttributedString()
        completeText.append(NSAttributedString(attachment: attachment))
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        completeText.append(NSAttributedString(string: text, attributes: textAttributes))
        
        return completeText
    }
}
