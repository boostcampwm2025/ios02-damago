//
//  DailyQuestionAPI.swift
//  DamagoNetwork
//
//  Created by Gemini on 1/20/26.
//

import Foundation

public enum DailyQuestionAPI {
    case fetch(accessToken: String)
}

extension DailyQuestionAPI: EndPoint {
    public var baseURL: URL {
        URL(string: BaseURL.string)!
    }
    
    public var path: String {
        switch self {
        case .fetch: "/fetch_daily_question"
        }
    }
    
    public var method: HTTPMethod {
        .get
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json; charset=utf-8"]
        switch self {
        case .fetch(let token):
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    public var body: Data? {
        return nil
    }
}
