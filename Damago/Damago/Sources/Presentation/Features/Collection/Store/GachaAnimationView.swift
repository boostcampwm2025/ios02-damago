//
//  GachaAnimationView.swift
//  Damago
//
//  Created by 김재영 on 1/29/26.
//

import SwiftUI

struct GachaAnimationView: View {
    private enum Constants {
        enum AnimationDuration {
            static let shakeCycle: Double = 0.05
            static let wobbleCycle: Double = 0.1
            static let reveal: Double = 0.5
            static let fadeOut: Double = 0.3
            static let finishDelay: Double = 0.3
        }
        
        enum Sleep {
            static let shakeStep = Duration.seconds(0.05)
            static let ejectWait = Duration.seconds(1.0)
            static let wobbleStep = Duration.seconds(0.15)
            static let revealWait = Duration.seconds(0.5)
        }
        
        enum Animation {
            static let shakeCount = 20
            static let wobbleCount = 3
            static let shakeOffset: CGFloat = 8
            static let capsuleEjectOffset = CGSize(width: 0, height: -150)
            static let capsuleEjectScale: CGFloat = 3.0
            static let wobbleAngle: Double = 15
        }
    }
    
    enum Phase {
        case idle
        case shaking
        case ejecting
        case wobbling
        case revealing
        case finished
    }

    @State private var phase: Phase = .idle
    @State private var shakeOffset: CGFloat = 0
    @State private var capsuleOffset = CGSize(width: 0, height: 150)
    @State private var capsuleScale: CGFloat = 0.5
    @State private var capsuleRotation: Double = 0
    @State private var flashOpacity: Double = 0
    
    @State private var isSkipped = false
    @State private var isFinished = false
    
    let machineImageName: String = "machine"
    let capsuleImageName: String = "capsule"

    var onFinish: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            let machineWidth = screenWidth * 0.7
            let machineHeight = machineWidth * 1.2
            
            let verticalOffset = screenHeight * 0.15
            let machinePositionX = screenWidth / 2
            let machinePositionY = (screenHeight / 2) - verticalOffset
            
            ZStack {
                Color.black.opacity(phase == .revealing ? 0.3 : 0)
                    .ignoresSafeArea()
                
                Image(machineImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: machineWidth, height: machineHeight)
                    .offset(x: shakeOffset)
                    .position(x: machinePositionX, y: machinePositionY)
                
                if showCapsule {
                    Image(capsuleImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .scaleEffect(capsuleScale)
                        .rotationEffect(.degrees(capsuleRotation))
                        .offset(capsuleOffset)
                        .position(
                            x: machinePositionX,
                            y: machinePositionY + (machineHeight / 2) - 20
                        )
                        .opacity(phase == .revealing ? 0 : 1)
                }
                
                Color.white.opacity(flashOpacity)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        skipButton
                    }
                    .padding(.bottom, 60)
                    .padding(.trailing, 20)
                }
            }
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .task {
            await play()
        }
    }
    
    private var showCapsule: Bool {
        phase != .idle && phase != .shaking && phase != .finished
    }
    
    private var skipButton: some View {
        Button(action: skip) {
            Text(">> SKIP")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.damagoPrimary)
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
                .background(Color.black.opacity(0.5))
                .cornerRadius(.largeCard)
        }
        .opacity(isFinished ? 0 : 1)
    }

    // MARK: - Animation Logic
    
    @MainActor
    private func play() async {
        await performShakeMachine()
        if isSkipped { return }
        
        await performEjectCapsule()
        if isSkipped { return }
        
        await performWobbleCapsule()
        if isSkipped { return }
        
        await performRevealResult()
        if isSkipped { return }
        
        finishAnimation()
    }
    
    @MainActor
    private func performShakeMachine() async {
        phase = .shaking
        let generator = UIImpactFeedbackGenerator(style: .medium)
        
        for _ in 0..<Constants.Animation.shakeCount {
            if isSkipped { return }
            generator.impactOccurred()
            withAnimation(.linear(duration: Constants.AnimationDuration.shakeCycle)) {
                shakeOffset = -Constants.Animation.shakeOffset
            }
            try? await Task.sleep(for: Constants.Sleep.shakeStep)
            
            withAnimation(.linear(duration: Constants.AnimationDuration.shakeCycle)) {
                shakeOffset = Constants.Animation.shakeOffset
            }
            try? await Task.sleep(for: Constants.Sleep.shakeStep)
        }
        
        withAnimation(.spring()) { shakeOffset = 0 }
    }
    
    @MainActor
    private func performEjectCapsule() async {
        phase = .ejecting
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            capsuleOffset = Constants.Animation.capsuleEjectOffset
            capsuleScale = Constants.Animation.capsuleEjectScale
        }
        try? await Task.sleep(for: Constants.Sleep.ejectWait)
    }
    
    @MainActor
    private func performWobbleCapsule() async {
        phase = .wobbling
        for _ in 0..<Constants.Animation.wobbleCount {
            if isSkipped { return }
            withAnimation(.linear(duration: Constants.AnimationDuration.wobbleCycle)) {
                capsuleRotation = -Constants.Animation.wobbleAngle
            }
            try? await Task.sleep(for: Constants.Sleep.wobbleStep)
            
            withAnimation(.linear(duration: Constants.AnimationDuration.wobbleCycle)) {
                capsuleRotation = Constants.Animation.wobbleAngle
            }
            try? await Task.sleep(for: Constants.Sleep.wobbleStep)
        }
        withAnimation(.spring()) { capsuleRotation = 0 }
    }
    
    @MainActor
    private func performRevealResult() async {
        phase = .revealing
        
        withAnimation(.easeOut(duration: Constants.AnimationDuration.reveal)) {
            flashOpacity = 1.0
        }
        try? await Task.sleep(for: Constants.Sleep.revealWait)
    }
    
    private func skip() {
        guard !isFinished else { return }
        isSkipped = true
        finishAnimation()
    }
    
    private func finishAnimation() {
        guard !isFinished else { return }
        isFinished = true
        
        phase = .finished
        withAnimation(.easeOut(duration: Constants.AnimationDuration.fadeOut)) {
            flashOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.AnimationDuration.finishDelay) {
            onFinish?()
        }
    }
}

#Preview {
    GachaAnimationView()
}
