//
//  DamagoWidgetBundle.swift
//  DamagoWidget
//
//  Created by 김재영 on 12/16/25.
//

import FirebaseAuth
import FirebaseCore
import OSLog
import SwiftUI
import WidgetKit

@main
struct DamagoWidgetBundle: WidgetBundle {
    init() {
        FirebaseApp.configure()

        do {
            try Auth.auth().useUserAccessGroup("B3PWYBKFUK.kr.codesquad.boostcamp10.Damago.SharedKeychain")
        } catch {
            SharedLogger.firebase.error("키체인 그룹 에러: \(error.localizedDescription)")
        }

        let assembler = WidgetAssembler()
        assembler.assemble(WidgetDIContainer.shared)
    }

    var body: some Widget {
        DamagoWidgetLiveActivity()
    }
}
