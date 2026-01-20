//
//  UIImage+.swift
//  Damago
//
//  Created by 김재영 on 1/20/26.
//

import UIKit

extension UIImage {
    func crop(rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
