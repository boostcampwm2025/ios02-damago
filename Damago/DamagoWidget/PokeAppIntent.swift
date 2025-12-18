//
//  PokeAppIntent.swift
//  DamagoWidget
//
//  Created by 박현수 on 12/18/25.
//

import AppIntents
import Foundation

enum NetworkError: Error {
    case invalidResponse
    case invalidStatusCode(Int, String)
}

struct PokeAppIntent: AppIntent {
    static var title: LocalizedStringResource = "콕 찌르기"
    static var description: IntentDescription = "상대방을 콕 찔러 알림을 보냅니다."
    
    @Parameter(title: "UDID")
    var udid: String
    
    init(udid: String) {
        self.udid = udid
    }
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "https://poke-wrjwddcv2q-uc.a.run.app") else {
            return .result()
        }
        
        var request = URLRequest(url: url)
        let body = ["udid": udid]
        
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidStatusCode(
                httpResponse.statusCode,
                String(data: data, encoding: .utf8) ?? "invalid data"
            )
        }
        return .result()
    }
}
