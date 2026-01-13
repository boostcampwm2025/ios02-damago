//
//  UserAPI.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public enum UserAPI {
    case generateCode(udid: String, fcmToken: String)
    case connectCouple(myCode: String, targetCode: String)
    case getUserInfo(udid: String)
}

extension UserAPI: EndPoint {
    public var baseURL: URL {
        URL(string: BaseURL.string)!
    }
    
    public var path: String {
        switch self {
        case .generateCode: "/generate_code"
        case .connectCouple: "/connect_couple"
        case .getUserInfo: "/get_user_info"
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
        case .generateCode(let udid, let fcmToken):
            parameters = ["udid": udid, "fcmToken": fcmToken]
            
        case .connectCouple(let myCode, let targetCode):
            parameters = ["myCode": myCode, "targetCode": targetCode]
            
        case .getUserInfo(let udid):
            parameters = ["udid": udid]
        }
        
        let validParameters = parameters.compactMapValues { $0 }
        return try? JSONSerialization.data(withJSONObject: validParameters)
    }
}
