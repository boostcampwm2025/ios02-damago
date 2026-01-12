//
//  NetworkProvider.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public final class NetworkProvider {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func request<T: Decodable>(_ endpoint: EndPoint) async throws -> T {
        let data = try await requestData(endpoint)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    public func requestString(_ endpoint: EndPoint) async throws -> String {
        let data = try await requestData(endpoint)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NetworkError.invalidResponse
        }
        return string
    }
    
    @discardableResult
    public func requestSuccess(_ endpoint: EndPoint) async throws -> Bool {
        _ = try await requestData(endpoint)
        return true
    }
    
    private func requestData(_ endpoint: EndPoint) async throws -> Data {
        var urlComponents = URLComponents(url: endpoint.baseURL.appending(path: endpoint.path), resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = endpoint.queryItems
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        request.httpBody = endpoint.body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidStatusCode(httpResponse.statusCode, "Server Error")
        }
        
        return data
    }
}
