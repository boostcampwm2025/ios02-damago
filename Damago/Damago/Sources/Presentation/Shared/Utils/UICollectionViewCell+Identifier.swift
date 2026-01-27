//
//  UICollectionViewCell+Identifier.swift
//  Damago
//
//  Created by 김재영 on 1/26/26.
//

import UIKit

extension UICollectionViewCell {
    static var reuseIdentifier: String { String(describing: self) }
}
