//
//  NetworkError.swift
//  Damago
//
//  Created by 김재영 on 1/7/26.
//

enum NetworkError: Error {
    case invalidStatusCode(Int, String)
    case invalidResponse
}
