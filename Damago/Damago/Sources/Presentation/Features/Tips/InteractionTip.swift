//
//  InteractionTip.swift
//  Damago
//
//  Created by 김재영 on 1/29/26.
//

import TipKit

struct InteractionTip {
    let dailyQuestion = ReusableTip(
        id: "dailyQuestion",
        title: "오늘의 질문",
        message: "우리의 생각과 일상을 나누며 서로를 더 깊이 알아가 보세요!\n두 분 모두 답변을 마치면 12시간마다 새로운 질문이 찾아와요."
    )
    
    let balanceGame = ReusableTip(
        id: "balanceGame",
        title: "밸런스 게임",
        message: "가벼운 질문으로 서로의 취향을 확인하고 보상도 챙겨보세요!\n우리는 얼마나 닮았는지, 찰떡궁합 테스트를 시작해볼까요?"
    )
}
