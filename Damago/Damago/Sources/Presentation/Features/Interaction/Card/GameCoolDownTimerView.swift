//
//  BalanceGameTimerView.swift
//  Damago
//
//  Created by Eden Landelyse on 1/25/26.
//

import SwiftUI

struct GameCoolDownTimerView: View {
    let targetDate: Date?
    let staticStatus: String?
    
    var body: some View {
        HStack(spacing: 4) {
            if let status = staticStatus {
                Text(status)
            } else if let target = targetDate {
                Text("다음 게임")
                Image(systemName: "clock")
                // SwiftUI의 내장 타이머 텍스트 사용 (별도 로직 없이 자동 업데이트)
                Text(timerInterval: Date()...target, countsDown: true)
            }
        }
        .font(.system(size: 14)) // body3 equivalent
        .foregroundColor(Color(uiColor: .textSecondary))
        .frame(maxWidth: .infinity, alignment: .trailing)
        .lineLimit(1)
    }
}
