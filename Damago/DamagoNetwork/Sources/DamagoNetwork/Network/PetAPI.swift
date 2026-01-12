//
//  PetAPI.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public enum PetAPI {
    case feed(damagoID: String)
}

extension PetAPI: EndPoint {
    public var baseURL: URL {
        URL(string: BaseURL.string)!
    }
    
    public var path: String {
        switch self {
        case .feed: "/feed"
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
        case .feed(let damagoID):
            parameters = ["damagoID": damagoID]
        }
        
        let validParameters = parameters.compactMapValues { $0 }
        return try? JSONSerialization.data(withJSONObject: validParameters)
    }
}
