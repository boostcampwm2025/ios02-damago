//
//  UserAPI.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public enum UserAPI {
    case generateCode(accessToken: String)
    case connectCouple(accessToken: String, targetCode: String)
    case getUserInfo(accessToken: String)
    case updateFCMToken(accessToken: String, fcmToken: String)
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
        case .updateFCMToken: "/update_fcm_token"
        }
    }
    
    public var method: HTTPMethod {
        .post
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json; charset=utf-8"]
        switch self {
        case .generateCode(let token),
             .connectCouple(let token, _),
             .getUserInfo(let token),
             .updateFCMToken(let token, _):
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    public var body: Data? {
        let parameters: [String: Any?]
        
        switch self {
        case .generateCode, .getUserInfo:
            parameters = [:]
            
        case .connectCouple(_, let targetCode):
            parameters = ["targetCode": targetCode]
            
        case .updateFCMToken(_, let fcmToken):
            parameters = ["fcmToken": fcmToken]
        }
        
        let validParameters = parameters.compactMapValues { $0 }
        return try? JSONSerialization.data(withJSONObject: validParameters)
    }
}
