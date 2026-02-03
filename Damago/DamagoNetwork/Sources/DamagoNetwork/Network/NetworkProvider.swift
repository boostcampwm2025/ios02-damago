//
//  NetworkProvider.swift
//  DamagoNetwork
//
//  Created by 김재영 on 1/12/26.
//

import Foundation

public protocol NetworkProvider: Sendable {
    func request<T: Decodable>(_ endpoint: EndPoint) async throws -> T
    func requestString(_ endpoint: EndPoint) async throws -> String
    @discardableResult func requestSuccess(_ endpoint: EndPoint) async throws -> Bool
}

public final class NetworkProviderImpl: NetworkProvider {
    private let session: URLSession
    private let onAuthenticationFailed: (@Sendable () -> Void)?

    public init(session: URLSession = .shared, onAuthenticationFailed: (@Sendable () -> Void)? = nil) {
        self.session = session
        self.onAuthenticationFailed = onAuthenticationFailed
    }
    
    public func request<T: Decodable>(_ endpoint: EndPoint) async throws -> T {
        let data = try await requestData(endpoint)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
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
        
        var retryCount = 0
        let maxRetries = 3
        
        while true {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    if httpResponse.statusCode == 401 {
                        onAuthenticationFailed?()
                    }
                    let body = String(data: data, encoding: .utf8) ?? "Unknown Server Error"
                    throw NetworkError.invalidStatusCode(httpResponse.statusCode, body)
                }
                
                return data
            } catch {
                let isRetryable: Bool
                
                switch error {
                case is URLError:
                    isRetryable = true
                    
                case let nsError as NSError where nsError.domain == NSPOSIXErrorDomain:
                    #if DEBUG
                    isRetryable = nsError.code == 53
                    #else
                    isRetryable = false
                    #endif
                default:
                    isRetryable = false
                }
                
                if isRetryable && retryCount < maxRetries {
                    retryCount += 1
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }
                
                throw NetworkError.connectionError(error)
            }
        }
    }
}
