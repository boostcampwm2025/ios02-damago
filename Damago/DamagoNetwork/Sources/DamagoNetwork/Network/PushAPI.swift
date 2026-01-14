//
//  PushAPI.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public enum PushAPI {
    case saveLiveActivityToken(accessToken: String, laStartToken: String?, laUpdateToken: String?)
    case poke(accessToken: String, message: String)
}

extension PushAPI: EndPoint {
    public var baseURL: URL {
        URL(string: BaseURL.string)!
    }
    
    public var path: String {
        switch self {
        case .saveLiveActivityToken: "/save_live_activity_token"
        case .poke: "/poke"
        }
    }
    
    public var method: HTTPMethod {
        .post
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json; charset=utf-8"]
        switch self {
        case let .saveLiveActivityToken(token, _, _), let .poke(token, _):
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    public var body: Data? {
        let parameters: [String: Any?]
        
        switch self {
        case let .saveLiveActivityToken(_,  laStartToken, laUpdateToken):
            parameters = [
                "laStartToken": laStartToken,
                "laUpdateToken": laUpdateToken
            ]

        case let .poke(_, message):
            parameters = ["message": message]
        }
        
        let validParameters = parameters.compactMapValues { $0 }
        return try? JSONSerialization.data(withJSONObject: validParameters)
    }
}
