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
            static let total: Double = 4.5
            static let shakeCycle: Double = 0.05
            static let shakeTotal: Double = 2.0
            static let eject: Double = 1.0
            static let wobbleCycle: Double = 0.15
            static let reveal: Double = 0.5
            static let fadeOut: Double = 0.3
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
    
    struct AnimationValues {
        var shakeOffset: CGFloat = 0
        var capsuleOffset = CGSize(width: 0, height: 150)
        var capsuleScale: CGFloat = 0.5
        var capsuleRotation: Double = 0
        var flashOpacity: Double = 0
        var capsuleOpacity: Double = 0
    }

    @State private var animationTrigger = false
    @State private var isSkipped = false
    @State private var isFinished = false
    @State private var animationTaskID = UUID()
    
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
                Color.black.opacity(isFinished ? 0 : 0.3)
                    .ignoresSafeArea()
                    .opacity(animationTrigger ? 1 : 0)
                
                Group {
                    Color.clear
                }
                .keyframeAnimator(
                    initialValue: AnimationValues(),
                    trigger: animationTrigger
                ) { _, values in
                    ZStack {
                        Image(machineImageName)
                            .resizable()
                            .interpolation(.medium)
                            .scaledToFit()
                            .frame(width: machineWidth, height: machineHeight)
                            .offset(x: values.shakeOffset)
                            .position(x: machinePositionX, y: machinePositionY)
                        
                        Image(capsuleImageName)
                            .resizable()
                            .interpolation(.medium)
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .scaleEffect(values.capsuleScale)
                            .rotationEffect(.degrees(values.capsuleRotation))
                            .offset(values.capsuleOffset)
                            .position(
                                x: machinePositionX,
                                y: machinePositionY + (machineHeight / 2) - 20
                            )
                            .opacity(values.capsuleOpacity)
                            .opacity(values.flashOpacity > 0.8 ? 0 : 1)
                        
                        Color.white.opacity(values.flashOpacity)
                            .ignoresSafeArea()
                    }
                } keyframes: { _ in
                    shakeMachineTrack()
                    capsuleOpacityTrack()
                    capsuleOffsetTrack()
                    capsuleScaleTrack()
                    capsuleRotationTrack()
                    revealFlashTrack()
                }
                
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
            .compositingGroup()
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .task(id: animationTaskID) {
            await runAnimationSequence()
        }
        .onAppear {
            start()
        }
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

    private func start() {
        animationTrigger = true
    }

    private func skip() {
        guard !isFinished else { return }
        isSkipped = true
        animationTaskID = UUID()
    }
    
    private func runAnimationSequence() async {
        if isSkipped {
            finishAnimation()
            return
        }
        
        guard animationTrigger else { return }
        
        try? await Task.sleep(for: .seconds(Constants.AnimationDuration.total))
        
        finishAnimation()
    }
    
    private func finishAnimation() {
        guard !isFinished else { return }
        isFinished = true
        onFinish?()
    }
    
    @KeyframesBuilder<AnimationValues>
    private func shakeMachineTrack() -> some Keyframes<AnimationValues> {
        KeyframeTrack(\.shakeOffset) {
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(-Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            LinearKeyframe(Constants.Animation.shakeOffset, duration: Constants.AnimationDuration.shakeCycle)
            SpringKeyframe(0, duration: 0.2)
        }
    }

    @KeyframesBuilder<AnimationValues>
    private func capsuleOpacityTrack() -> some Keyframes<AnimationValues> {
        KeyframeTrack(\.capsuleOpacity) {
            LinearKeyframe(0, duration: Constants.AnimationDuration.shakeTotal)
            LinearKeyframe(1.0, duration: 0.01)
        }
    }

    @KeyframesBuilder<AnimationValues>
    private func capsuleOffsetTrack() -> some Keyframes<AnimationValues> {
        KeyframeTrack(\.capsuleOffset) {
            LinearKeyframe(CGSize(width: 0, height: 150), duration: Constants.AnimationDuration.shakeTotal)
            SpringKeyframe(Constants.Animation.capsuleEjectOffset, duration: Constants.AnimationDuration.eject)
        }
    }

    @KeyframesBuilder<AnimationValues>
    private func capsuleScaleTrack() -> some Keyframes<AnimationValues> {
        KeyframeTrack(\.capsuleScale) {
            LinearKeyframe(0.5, duration: Constants.AnimationDuration.shakeTotal)
            SpringKeyframe(Constants.Animation.capsuleEjectScale, duration: Constants.AnimationDuration.eject)
        }
    }

    @KeyframesBuilder<AnimationValues>
    private func capsuleRotationTrack() -> some Keyframes<AnimationValues> {
        KeyframeTrack(\.capsuleRotation) {
            LinearKeyframe(0, duration: Constants.AnimationDuration.shakeTotal + Constants.AnimationDuration.eject)
            LinearKeyframe(-Constants.Animation.wobbleAngle, duration: Constants.AnimationDuration.wobbleCycle)
            LinearKeyframe(Constants.Animation.wobbleAngle, duration: Constants.AnimationDuration.wobbleCycle)
            LinearKeyframe(-Constants.Animation.wobbleAngle, duration: Constants.AnimationDuration.wobbleCycle)
            LinearKeyframe(Constants.Animation.wobbleAngle, duration: Constants.AnimationDuration.wobbleCycle)
            LinearKeyframe(-Constants.Animation.wobbleAngle, duration: Constants.AnimationDuration.wobbleCycle)
            LinearKeyframe(Constants.Animation.wobbleAngle, duration: Constants.AnimationDuration.wobbleCycle)
            SpringKeyframe(0, duration: 0.2)
        }
    }

    @KeyframesBuilder<AnimationValues>
    private func revealFlashTrack() -> some Keyframes<AnimationValues> {
        KeyframeTrack(\.flashOpacity) {
            LinearKeyframe(0, duration: 4.0)
            CubicKeyframe(1.0, duration: Constants.AnimationDuration.reveal)
            LinearKeyframe(0, duration: Constants.AnimationDuration.fadeOut)
        }
    }
}

#Preview {
    GachaAnimationView()
}
