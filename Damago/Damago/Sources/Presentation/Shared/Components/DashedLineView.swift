//
//  DashedLineView.swift
//  Damago
//
//  Created by 박현수 on 1/15/26.
//

import UIKit

final class DashedLineView: UIView {
    private let shapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.height / 2))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height / 2))
        shapeLayer.path = path.cgPath
    }

    private func setupLayer() {
        shapeLayer.strokeColor = UIColor.lightGray.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [4, 4]
        shapeLayer.fillColor = nil
        layer.addSublayer(shapeLayer)
    }
}
