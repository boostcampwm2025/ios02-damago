//
//  BubbleView.swift
//  Damago
//
//  Created by 박현수 on 1/7/26.
//

import UIKit

final class BubbleView: UIView {
    enum BubbleOrientation {
        case left, right
    }

    private enum Constants {
        static let mainOvalHeightRatio: CGFloat = 0.75
        static let contentInsetRatio: CGFloat = 0.15
        static let tailMidSizeRatio: CGFloat = 0.14
        static let tailSmallSizeRatio: CGFloat = 0.1

        static let midTailYRatio: CGFloat = 0.8
        static let midTailXRatioLeft: CGFloat = 0.22

        static let smallTailYRatio: CGFloat = 0.92
        static let smallTailXRatioLeft: CGFloat = 0.1
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private let borderLayer = CAShapeLayer()
    private var oldBounds: CGRect = .zero

    var orientation: BubbleOrientation = .left {
        didSet { setNeedsLayout() }
    }

    var borderColor: UIColor = .black {
        didSet { borderLayer.strokeColor = borderColor.cgColor }
    }

    var bubbleBackgroundColor: UIColor = .white {
        didSet { borderLayer.fillColor = bubbleBackgroundColor.cgColor }
    }

    var borderWidth: CGFloat = 2.0 {
        didSet { borderLayer.lineWidth = borderWidth }
    }

    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(imageView)

        borderLayer.fillColor = bubbleBackgroundColor.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth

        layer.insertSublayer(borderLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds != oldBounds else { return }
        oldBounds = bounds

        updateLayout()
    }

    private func updateLayout() {
        let width = bounds.width
        let height = bounds.height

        let mainOvalRect = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height * Constants.mainOvalHeightRatio
        )

        let insetW = mainOvalRect.width * Constants.contentInsetRatio
        let insetH = mainOvalRect.height * Constants.contentInsetRatio
        imageView.frame = mainOvalRect.insetBy(dx: insetW, dy: insetH)

        let path = makeBubblePath(in: bounds, mainRect: mainOvalRect)
        borderLayer.path = path.cgPath
        borderLayer.frame = bounds
    }

    func makeBubblePath(in rect: CGRect, mainRect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        let isLeft = orientation == .left

        path.append(UIBezierPath(ovalIn: mainRect))

        let midSize = width * Constants.tailMidSizeRatio
        let midXLeft = width * Constants.midTailXRatioLeft
        let midX = isLeft ? midXLeft : (width - midXLeft - midSize)

        let midRect = CGRect(
            x: midX,
            y: height * Constants.midTailYRatio,
            width: midSize,
            height: midSize
        )
        path.append(UIBezierPath(ovalIn: midRect))

        let smallSize = width * Constants.tailSmallSizeRatio
        let smallXLeft = width * Constants.smallTailXRatioLeft
        let smallX = isLeft ? smallXLeft : (width - smallXLeft - smallSize)

        let smallRect = CGRect(
            x: smallX,
            y: height * Constants.smallTailYRatio,
            width: smallSize,
            height: smallSize
        )
        path.append(UIBezierPath(ovalIn: smallRect))

        return path
    }
}
