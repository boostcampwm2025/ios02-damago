//
//  DamagoAPI.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public enum DamagoAPI {
    case feed(accessToken: String, damagoID: String)
    case create(accessToken: String)
}

extension DamagoAPI: EndPoint {
    public var baseURL: URL {
        URL(string: BaseURL.string)!
    }
    
    public var path: String {
        switch self {
        case .feed: "/feed"
        case .create: "/create_damago"
        }
    }
    
    public var method: HTTPMethod {
        .post
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json; charset=utf-8"]
        switch self {
        case .feed(let token, _):
            headers["Authorization"] = "Bearer \(token)"
        case .create(let token):
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    public var body: Data? {
        let parameters: [String: Any?]
        
        switch self {
        case .feed(_, let damagoID):
            parameters = ["damagoID": damagoID]
        case .create:
            return nil
        }
        
        let validParameters = parameters.compactMapValues { $0 }
        return try? JSONSerialization.data(withJSONObject: validParameters)
    }
}
