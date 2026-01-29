//
//  HistoryAPI.swift
//  DamagoNetwork
//
//  Created by 박현수 on 1/26/26.
//

import Foundation

public enum HistoryAPI {
    case fetchDailyQuestionHistory(accessToken: String, limit: Int)
    case fetchBalanceGameHistory(accessToken: String, limit: Int)
}

extension HistoryAPI: EndPoint {
    public var baseURL: URL {
        URL(string: BaseURL.string)!
    }
    
    public var path: String {
        "/fetch_history"
    }
    
    public var method: HTTPMethod {
        .get
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json; charset=utf-8"]
        switch self {
        case .fetchDailyQuestionHistory(let token, _), .fetchBalanceGameHistory(let token, _):
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    public var body: Data? {
        nil
    }
    
    public var queryItems: [URLQueryItem]? {
        switch self {
        case .fetchDailyQuestionHistory(_, let limit):
            return [
                URLQueryItem(name: "type", value: "daily_question"),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        case .fetchBalanceGameHistory(_, let limit):
            return [
                URLQueryItem(name: "type", value: "balance_game"),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        }
    }
}
