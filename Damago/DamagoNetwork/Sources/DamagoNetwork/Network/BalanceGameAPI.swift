//
//  BalanceGameAPI.swift
//  DamagoNetwork
//
//  Created by Eden Landelyse on 1/26/26.
//

import Foundation

public enum BalanceGameAPI {
    case fetch(accessToken: String)
    case submit(accessToken: String, gameID: String, choice: Int)
}

extension BalanceGameAPI: EndPoint {
    public var baseURL: URL {
        URL(string: BaseURL.string)!
    }
    
    public var path: String {
        switch self {
        case .fetch: "/fetch_balance_game"
        case .submit: "/submit_balance_game"
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
        case .submit(_, let gameID, let choice):
            let parameters: [String: Any] = [
                "gameID": gameID,
                "choice": choice
            ]
            return try? JSONSerialization.data(withJSONObject: parameters)
        }
    }
}
