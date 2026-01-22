//
//  DailyQuestionAPI.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/20/26.
//

import Foundation

public enum DailyQuestionAPI {
    case fetch(accessToken: String)
    case submit(accessToken: String, questionID: String, answer: String)
}

extension DailyQuestionAPI: EndPoint {
    public var baseURL: URL {
        URL(string: BaseURL.string)!
    }
    
    public var path: String {
        switch self {
        case .fetch: "/fetch_daily_question"
        case .submit: "/submit_daily_question"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .fetch: .get
        case .submit: .post
        }
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json; charset=utf-8"]
        switch self {
        case .fetch(let token), .submit(let token, _, _):
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    public var body: Data? {
        switch self {
        case .fetch:
            return nil
        case .submit(_, let questionID, let answer):
            let parameters = [
                "questionID": questionID,
                "answer": answer
            ]
            return try? JSONSerialization.data(withJSONObject: parameters)
        }
    }
}
