//
//  NetworkError.swift
//  Damago
//
//  Created by Eden Landelyse on 1/8/26.
//


enum NetworkError: Error {
    case invalidResponse
    case invalidStatusCode(Int, String)
}