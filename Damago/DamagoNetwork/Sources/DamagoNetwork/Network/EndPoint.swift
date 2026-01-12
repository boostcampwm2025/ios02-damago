//
//  EndPoint.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public protocol EndPoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var queryItems: [URLQueryItem]? { get }
}

public extension EndPoint {
    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
    var body: Data? { nil }
    var queryItems: [URLQueryItem]? { nil }
}
