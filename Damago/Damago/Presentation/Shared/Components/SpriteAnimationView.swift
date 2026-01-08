//
//  SpriteAnimationView.swift
//  Damago
//
//  Created by loyH on 1/7/26.
//

import UIKit
import SpriteKit

final class SpriteAnimationView: UIView {
    private let skView: SKView
    private var scene: SKScene?
    
    /// 애니메이션으로 표시 될 프레임 이름 배열
    private var pendingFrameNames: [String]?
    
    /// 저장된 기본 애니메이션 프레임 이름 배열
    private let defaultFrameNames: [String]?
    
    var animationDuration: TimeInterval = 1.0
    let frameCount: Int
    
    /// 포커스 시스템 지원 여부
    /// 포커스 관련 경고를 방지
    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { [] }
    
    // MARK: - Initialization
    
    init(frame: CGRect = .zero, defaultFrameNames: [String]? = nil, frameCount: Int) {
        self.defaultFrameNames = defaultFrameNames
        self.frameCount = frameCount
        skView = SKView(frame: .zero)
        super.init(frame: frame)
        setupSKView()
    }
    
    convenience init(defaultDamagoName: String, frameCount: Int = 6) {
        let frameNames = (0..<frameCount).map { defaultDamagoName + String(format: "%02d", $0) }
        
        self.init(frame: .zero, defaultFrameNames: frameNames, frameCount: frameCount)
    }
    
    required init?(coder: NSCoder) {
        defaultFrameNames = nil
        frameCount = 0
        skView = SKView(frame: .zero)
        super.init(coder: coder)
        setupSKView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 기존 씬이 있는 경우 크기와 위치 업데이트
        if let scene = scene, let spriteNode = scene.children.first as? SKSpriteNode {
            scene.size = bounds.size
            spriteNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
            
            // 텍스처 크기에 맞춰 스프라이트 노드 스케일 조정 (aspectFit 유지)
            if let texture = spriteNode.texture {
                let scale = min(bounds.width / texture.size().width, bounds.height / texture.size().height)
                spriteNode.xScale = scale
                spriteNode.yScale = scale
            }
        }
        
        // bounds가 설정된 후 대기 중인 애니메이션 시작
        if let frameNames = pendingFrameNames, bounds.width > 0 && bounds.height > 0 {
            pendingFrameNames = nil
            animate(withFrameNames: frameNames)
        }
    }
    
    private func setupSKView() {
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.backgroundColor = .clear
        skView.ignoresSiblingOrder = true
        skView.allowsTransparency = true
        skView.isMultipleTouchEnabled = false
        addSubview(skView)
        
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: topAnchor),
            skView.leadingAnchor.constraint(equalTo: leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Animation
extension SpriteAnimationView {
    /// 애니메이션 이름만 지정하면 00부터 (frameCount-1)까지 프레임을 자동으로 로드
    func animate(damagoName: String, repeatCount: Int? = nil) {
        let frameNames = (0..<frameCount).map { damagoName + String(format: "%02d", $0) }
        animate(withFrameNames: frameNames, repeatCount: repeatCount)
    }
    
    /// 프레임 이름 배열로 애니메이션 재생
    /// repeatCount만큼 반복 재생 (nil이면 무한 재생)
    private func animate(withFrameNames frameNames: [String], repeatCount: Int? = nil) {
        // 빈 배열 체크
        guard !frameNames.isEmpty else { return }
        
        // bounds가 설정되지 않은 경우 대기 (layoutSubviews에서 자동 시작)
        guard bounds.width > 0 && bounds.height > 0 else {
            pendingFrameNames = frameNames
            return
        }
        
        // 텍스처 로드 실패 시 종료
        guard let textures = loadTextures(from: frameNames), !textures.isEmpty else { return }
        
        // 씬과 Sprite 노드 생성
        let scene = createScene()
        let spriteNode = createSpriteNode(with: textures[0], in: scene)
        let animationAction = createAnimationAction(with: textures, repeatCount: repeatCount)
        
        // 기본 애니메이션이 설정되고 repeatCount가 지정된 경우 복귀, 아니면 무한 반복
        if let defaultFrameNames,
           let defaultTextures = loadTextures(from: defaultFrameNames),
           repeatCount != nil,
           !defaultTextures.isEmpty {
            // 기본 애니메이션으로 복귀 (무한 반복)
            let defaultAction = createAnimationAction(with: defaultTextures, repeatCount: nil)
            spriteNode.run(SKAction.sequence([animationAction, defaultAction]))
        } else {
            // 기본 애니메이션 없거나 repeatCount가 nil인 경우 지정된 액션만 실행
            spriteNode.run(animationAction)
        }
        
        // 씬에 노드 추가 후 표시
        scene.addChild(spriteNode)
        self.scene = scene
        skView.presentScene(scene)
    }
    
    /// 현재 실행 중인 애니메이션을 중지하고 리소스를 정리
    func stopAnimation() {
        scene?.removeAllActions()
        scene?.removeAllChildren()
        skView.presentScene(nil)
        scene = nil
    }
}

// MARK: - Private Helpers
private extension SpriteAnimationView {
    /// 프레임 이름 배열에서 텍스처를 로드
    func loadTextures(from frameNames: [String]) -> [SKTexture]? {
        let textures = frameNames.compactMap { frameName -> SKTexture? in
            // UIImage를 먼저 시도하고, 실패하면 SKTexture의 imageNamed 사용
            let texture = UIImage(named: frameName).map { SKTexture(image: $0) }
                ?? SKTexture(imageNamed: frameName)

            // 유효한 크기를 가진 텍스처만 반환
            guard texture.size().width > 0 && texture.size().height > 0 else { return nil }

            // 픽셀 아트 스타일의 선명한 렌더링을 위한 필터링 모드 설정
            texture.filteringMode = .nearest
            return texture
        }
        return textures.isEmpty ? nil : textures
    }

    /// 새로운 SKScene을 생성
    func createScene() -> SKScene {
        let scene = SKScene(size: bounds.size)
        scene.backgroundColor = .clear
        scene.scaleMode = .aspectFit
        return scene
    }

    /// Sprite 노드를 생성하고 설정
    func createSpriteNode(with texture: SKTexture, in scene: SKScene) -> SKSpriteNode {
        let spriteNode = SKSpriteNode(texture: texture)
        spriteNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        spriteNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        // aspectFit 방식으로 스케일 계산
        let scale = min(bounds.width / texture.size().width, bounds.height / texture.size().height)
        spriteNode.xScale = scale
        spriteNode.yScale = scale

        return spriteNode
    }

    /// 애니메이션 액션을 생성
    /// 텍스처 배열을 사용하여 프레임 애니메이션을 생성하고, 반복 횟수에 따라 반복 또는 무한 반복 액션을 반환
    func createAnimationAction(with textures: [SKTexture], repeatCount: Int?) -> SKAction {
        // 각 프레임의 재생 시간 계산
        let baseAnimation = SKAction.animate(
            with: textures,
            timePerFrame: animationDuration / Double(textures.count)
        )

        // 반복 횟수가 지정된 경우 해당 횟수만큼 반복, 아니면 무한 반복
        return repeatCount.map { SKAction.repeat(baseAnimation, count: $0) }
            ?? SKAction.repeatForever(baseAnimation)
    }
}
