//
//  NetworkError.swift
//  Damago
//
//  Created by 김재영 on 1/7/26.
//

import Foundation

public enum NetworkError: LocalizedError {
    case invalidStatusCode(Int, String)
    case invalidResponse
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case let .invalidStatusCode(code, message):
            return "Invalid status code: \(code).\n\(message)"
        case .invalidResponse:
            return "Invalid response"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}
