//
//  PushAPI.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public enum PushAPI {
    case saveLiveActivityToken(udid: String, laStartToken: String?, laUpdateToken: String?)
    case poke(udid: String)
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
        ["Content-Type": "application/json; charset=utf-8"]
    }
    
    public var body: Data? {
        let parameters: [String: Any?]
        
        switch self {
        case .saveLiveActivityToken(let udid, let laStartToken, let laUpdateToken):
            parameters = [
                "udid": udid,
                "laStartToken": laStartToken,
                "laUpdateToken": laUpdateToken
            ]

        case .poke(let udid):
            parameters = ["udid": udid]
        }
        
        let validParameters = parameters.compactMapValues { $0 }
        return try? JSONSerialization.data(withJSONObject: validParameters)
    }
}
