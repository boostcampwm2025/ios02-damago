//
//  CodeConnectionViewModel.swift
//  Damago
//
//  Created by Eden Landelyse on 12/17/25.
//

final class CodeConnectionViewModel {
    private let code: String = "exapleCode_123"
    var onConnected: (() -> Void)?

    func connectCouple(pairCode: String) async throws {
        // 입력받은 코드를 통해 cloud functions에 연결 요청
        // 연결 성공 시 home 화면으로 이동
        await MainActor.run { [weak self] in
            self?.onConnected?()
        }
    }

    func resolveMyCode() async throws -> String {
        // UserDefaults에서 코드를 가져오는 메서드
        // UserDefaults에 없다면 cloud functions에 생성을 요청하는 메서드
        code
    }
}
