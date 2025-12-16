//
//  DamagoWidgetLiveActivity.swift
//  DamagoWidget
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DamagoWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DamagoAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Image(context.state.petImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button("콕 찌르기") {
                        print("찔렸습니다.")
                    }
                }
            } compactLeading: {
                Image(context.state.petImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(Rectangle())
            } compactTrailing: {
                Image(context.state.statusImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
            } minimal: {
                Image(context.state.petImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(Rectangle())
            }
        }
    }
}

extension DamagoAttributes {
    fileprivate static var preview: DamagoAttributes {
        DamagoAttributes(petName: "Base Pet")
    }
}

extension DamagoAttributes.ContentState {
    fileprivate static var base: DamagoAttributes.ContentState {
        .init(petImageName: "PetBase", statusImageName: "BaseHeart")
     }

     fileprivate static var hungry: DamagoAttributes.ContentState {
         .init(petImageName: "PetHungry", statusImageName: "NeedFood")
     }
}

#Preview("Notification", as: .content, using: DamagoAttributes.preview) {
   DamagoWidgetLiveActivity()
} contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
}
