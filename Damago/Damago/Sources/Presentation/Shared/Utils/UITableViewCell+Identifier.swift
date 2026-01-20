//
//  UITableViewCell+Identifier.swift
//  Damago
//
//  Created by 박현수 on 1/20/26.
//

import UIKit

extension UITableViewCell {
    static var reuseIdentifier: String { String(describing: self) }
}
