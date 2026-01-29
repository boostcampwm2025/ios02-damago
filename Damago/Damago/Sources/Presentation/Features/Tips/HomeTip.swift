//
//  HomeTip.swift
//  Damago
//
//  Created by 김재영 on 1/29/26.
//

import TipKit

struct HomeTip {
    let poke = ReusableTip(
        id: "pokeTip",
        title: "콕 찌르기",
        message: "상대방에게 마음을 전달해보세요!"
    )
    
    let feed = ReusableTip(
        id: "feedTip",
        title: "먹이 주기",
        message: "다마고에게 먹이를 주면 위 성장 게이지가 차올라요!",
    )
}
