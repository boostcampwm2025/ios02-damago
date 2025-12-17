//
//  LockScreenLiveActivityView.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import SwiftUI
import WidgetKit

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<DamagoAttributes>
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    var body: some View {
        ZStack {
            if isLuminanceReduced {
                Image(context.state.petImageName)
                    .saturation(0)
                    .opacity(0.6)
            } else {
                Image(context.state.petImageName)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.8))
    }
}
