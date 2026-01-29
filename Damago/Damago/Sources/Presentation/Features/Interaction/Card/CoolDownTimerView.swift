//
//  CoolDownTimerView.swift
//  Damago
//
//  Created by Eden Landelyse on 1/25/26.
//

import SwiftUI

struct CoolDownTimerView: View {
    let message: String
    let targetDate: Date?
    
    var body: some View {
        HStack(spacing: .spacingXS) {
            Spacer()
            Text(message)
            if let target = targetDate, target > Date() {
                Image(systemName: "clock")
                // SwiftUI의 내장 타이머 텍스트 사용 (별도 로직 없이 자동 업데이트)
                Text(timerInterval: Date()...target, countsDown: true)
            }
        }
        .font(.system(size: 14)) // body3 equivalent
        .foregroundColor(Color(uiColor: .textSecondary))
        .lineLimit(1)
    }
}
