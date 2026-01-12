//
//  Labels.swift
//  Damago
//
//  Created by 박현수 on 1/8/26.
//

import UIKit

class PaddingLabel: UILabel {
    var padding: UIEdgeInsets

    init(padding: UIEdgeInsets = .init(top: .spacingS, left: .spacingM, bottom: .spacingS, right: .spacingM)) {
        self.padding = padding
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        self.padding = .init(top: .spacingS, left: .spacingM, bottom: .spacingS, right: .spacingM)
        super.init(coder: coder)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += padding.top + padding.bottom
        contentSize.width += padding.left + padding.right

        return contentSize
    }
}

final class CapsuleLabel: PaddingLabel {
    override init(padding: UIEdgeInsets = .init(top: .spacingS, left: .spacingM, bottom: .spacingS, right: .spacingM)) {
        super.init(padding: padding)
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }
}

final class CircleTextBadge: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    var font: UIFont {
        get { label.font }
        set { label.font = newValue }
    }

    var textColor: UIColor {
        get { label.textColor }
        set { label.textColor = newValue }
    }

    private let padding: CGFloat

    init(padding: CGFloat = 8) {
        self.padding = padding
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        self.padding = 8
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        clipsToBounds = true
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -padding),

            widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }
}
