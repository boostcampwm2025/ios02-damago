//
//  ViewController.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import UIKit
import Gifu
import ImageIO

@MainActor
final class ViewController: UIViewController {
    private var isShowingTouchAnimation = false
    
    private let gifImageView: GIFImageView = {
        let imageView = GIFImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(gifImageView)
        
        NSLayoutConstraint.activate([
            gifImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gifImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gifImageView.widthAnchor.constraint(equalToConstant: 200),
            gifImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        setupTapGesture()
        gifImageView.animate(withGIFNamed: "dog")
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGifTapAction(_:)))
        gifImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func handleGifTapAction(_ sender: UITapGestureRecognizer) {
        guard !isShowingTouchAnimation else { return }
        
        isShowingTouchAnimation = true
        gifImageView.stopAnimatingGIF()
        gifImageView.animate(withGIFNamed: "dog_touch")
        
        // dog_touch GIF의 실제 재생 시간을 가져와서 한 번만 재생
        let duration = getGIFDuration(named: "dog_touch")
        
        Task {
            try? await Task.sleep(for: .seconds(duration))
            isShowingTouchAnimation = false
            gifImageView.stopAnimatingGIF()
            gifImageView.animate(withGIFNamed: "dog")
        }
    }
}

extension ViewController {
    private func getGIFDuration(named: String) -> TimeInterval {
        // 번들에서 GIF 파일 URL 가져오기
        guard let url = Bundle.main.url(forResource: named, withExtension: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return 1.5 // 기본값
        }
        
        // GIF의 총 프레임 수 확인
        let frameCount = CGImageSourceGetCount(source)
        var totalDuration: TimeInterval = 0
        
        // 각 프레임의 딜레이 시간을 합산하여 총 재생 시간 계산
        for index in 0..<frameCount {
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
                  let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                  let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double else {
                continue
            }
            totalDuration += delayTime
        }
        
        // 계산된 시간이 있으면 반환, 없으면 기본값 반환
        return totalDuration > 0 ? totalDuration : 1.5
    }
}
