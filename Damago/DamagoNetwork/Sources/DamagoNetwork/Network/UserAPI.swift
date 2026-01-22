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
    case updateUserInfo(accessToken: String, nickname: String?, anniversaryDate: String?, useFCM: Bool?, useActivity: Bool?)
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
        case .updateUserInfo: "/update_user_info"
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
             .updateFCMToken(let token, _),
             .updateUserInfo(let token, _, _, _, _):
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
            
        case .updateUserInfo(_, let nickname, let anniversaryDate, let useFCM, let useActivity):
            parameters = [
                "nickname": nickname,
                "anniversaryDate": anniversaryDate,
                "useFCM": useFCM,
                "useActivity": useActivity
            ]
        }
        
        let validParameters = parameters.compactMapValues { $0 }
        return try? JSONSerialization.data(withJSONObject: validParameters)
    }
}
