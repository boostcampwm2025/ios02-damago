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
    case connectionError(Error)

    public var errorDescription: String? {
        switch self {
        case let .invalidStatusCode(code, message):
            return "Invalid status code: \(code).\n\(message)"
        case .invalidResponse:
            return "Invalid response"
        case .invalidURL:
            return "Invalid URL"
        case .connectionError(let error):
            let nsError = error as NSError
            let domain = nsError.domain
            let code = nsError.code
            let description = nsError.localizedDescription
            
            return """
            [Network Connection Error]
            Description: \(description)
            Domain: \(domain)
            Code: \(code)
            """
        }
    }
}
