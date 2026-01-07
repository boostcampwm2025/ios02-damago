import UIKit

extension CGFloat {
    static var spacingXS: CGFloat = 4
    static var spacingS: CGFloat = 8
    static var spacingM: CGFloat = 16
    static var spacingL: CGFloat = 24
    static var spacingXL: CGFloat = 32

    static var largeCard: CGFloat = 20
    static var mediumButton: CGFloat = 12
    static var smallElement: CGFloat = 6
}

extension UIView {
    func padding(_ spacing: CGFloat) {
        layoutMargins = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
    }

    func padding(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        layoutMargins = UIEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
    }

    func cornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
}
