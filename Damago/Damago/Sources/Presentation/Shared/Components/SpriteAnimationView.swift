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
    
    /// 스프라이트 시트 정보
    private let spriteSheetName: String
    private let spriteSheetColumns: Int
    
    var animationDuration: TimeInterval = 1.0
    
    /// 포커스 시스템 지원 여부
    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { [] }
    
    // MARK: - Initialization
    
    /// 시트 이름만으로 자동 감지하는 초기화 (가로 1열, 정사각형 프레임 가정)
    init(frame: CGRect = .zero, spriteSheetName: String) {
        self.spriteSheetName = spriteSheetName
        self.spriteSheetColumns = Self.autoDetectColumns(sheetName: spriteSheetName) ?? 4
        skView = SKView(frame: .zero)
        super.init(frame: frame)
        setupSKView()
    }
    
    /// columns를 직접 지정하는 초기화
    init(frame: CGRect = .zero, spriteSheetName: String, columns: Int) {
        self.spriteSheetName = spriteSheetName
        self.spriteSheetColumns = columns
        skView = SKView(frame: .zero)
        super.init(frame: frame)
        setupSKView()
    }
    
    required init?(coder: NSCoder) {
        spriteSheetName = ""
        spriteSheetColumns = 4
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
            
            if let texture = spriteNode.texture {
                let scale = min(bounds.width / texture.size().width, bounds.height / texture.size().height)
                spriteNode.xScale = scale
                spriteNode.yScale = scale
            }
        }
        
        // 애니메이션이 시작되지 않은 경우 자동 시작
        if bounds.width > 0 && bounds.height > 0 && scene == nil {
            animate()
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
    /// 애니메이션 재생 (기본 시트 사용)
    func animate(repeatCount: Int? = nil) {
        animate(spriteSheetName: spriteSheetName, columns: spriteSheetColumns, repeatCount: repeatCount)
    }
    
    /// 다른 시트로 애니메이션 재생
    func animate(spriteSheetName: String, repeatCount: Int? = nil) {
        guard let columns = Self.autoDetectColumns(sheetName: spriteSheetName) else { return }
        animate(spriteSheetName: spriteSheetName, columns: columns, repeatCount: repeatCount)
    }
    
    /// columns를 지정하여 애니메이션 재생
    func animate(spriteSheetName: String, columns: Int, repeatCount: Int? = nil) {
        guard bounds.width > 0 && bounds.height > 0 else { return }
        guard let textures = loadTexturesFromSheet(sheetName: spriteSheetName, columns: columns), !textures.isEmpty else { return }
        
        let scene = createScene()
        let spriteNode = createSpriteNode(with: textures[0], in: scene)
        let animationAction = createAnimationAction(with: textures, repeatCount: repeatCount)
        
        // 다른 시트로 변경하고 repeatCount가 지정된 경우 기본 애니메이션으로 복귀
        if spriteSheetName != self.spriteSheetName,
           repeatCount != nil,
           let defaultTextures = loadTexturesFromSheet(sheetName: self.spriteSheetName, columns: self.spriteSheetColumns),
           !defaultTextures.isEmpty {
            let defaultAction = createAnimationAction(with: defaultTextures, repeatCount: nil)
            spriteNode.run(SKAction.sequence([animationAction, defaultAction]))
        } else {
            spriteNode.run(animationAction)
        }
        
        scene.addChild(spriteNode)
        self.scene = scene
        skView.presentScene(scene)
    }
    
    /// 애니메이션 중지
    func stopAnimation() {
        scene?.removeAllActions()
        scene?.removeAllChildren()
        skView.presentScene(nil)
        scene = nil
    }
}

// MARK: - Private Helpers
private extension SpriteAnimationView {
    /// 가로 1열, 정사각형 프레임 가정으로 columns 자동 감지
    static func autoDetectColumns(sheetName: String) -> Int? {
        guard let image = UIImage(named: sheetName) else { return nil }
        let sheetSize = image.size
        let frameSize = sheetSize.height
        let columns = Int(sheetSize.width / frameSize)
        return columns > 0 && frameSize > 0 ? columns : nil
    }
    
    /// 스프라이트 시트에서 텍스처를 로드 (가로 1열 가정)
    func loadTexturesFromSheet(sheetName: String, columns: Int) -> [SKTexture]? {
        let sheet: SKTexture?
        if let image = UIImage(named: sheetName) {
            sheet = SKTexture(image: image)
        } else {
            sheet = SKTexture(imageNamed: sheetName)
        }
        guard let sheet = sheet else {
            return nil
        }
        
        sheet.filteringMode = .nearest
        let frameWidth = 1.0 / CGFloat(columns)
        
        var textures: [SKTexture] = []
        for col in 0..<columns {
            let rect = CGRect(x: CGFloat(col) * frameWidth, y: 0, width: frameWidth, height: 1.0)
            let tex = SKTexture(rect: rect, in: sheet)
            tex.filteringMode = .nearest
            textures.append(tex)
        }
        
        return textures.isEmpty ? nil : textures
    }
    
    /// SKScene 생성
    func createScene() -> SKScene {
        let scene = SKScene(size: bounds.size)
        scene.backgroundColor = .clear
        scene.scaleMode = .aspectFit
        return scene
    }
    
    /// Sprite 노드 생성 및 설정
    func createSpriteNode(with texture: SKTexture, in scene: SKScene) -> SKSpriteNode {
        let spriteNode = SKSpriteNode(texture: texture)
        spriteNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        spriteNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let scale = min(bounds.width / texture.size().width, bounds.height / texture.size().height)
        spriteNode.xScale = scale
        spriteNode.yScale = scale
        
        return spriteNode
    }
    
    /// 애니메이션 액션 생성
    func createAnimationAction(with textures: [SKTexture], repeatCount: Int?) -> SKAction {
        let baseAnimation = SKAction.animate(
            with: textures,
            timePerFrame: animationDuration / Double(textures.count)
        )
        return repeatCount.map { SKAction.repeat(baseAnimation, count: $0) }
            ?? SKAction.repeatForever(baseAnimation)
    }
}
