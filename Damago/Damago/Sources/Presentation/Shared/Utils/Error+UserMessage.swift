//
//  Error+UserMessage.swift
//  Damago
//
//  Created by Auto on 1/26/26.
//

import Foundation
import DamagoNetwork

extension Error {
    /// 사용자에게 표시할 친화적인 에러 메시지로 변환
    var userFriendlyMessage: String {
        // NetworkError 처리
        if let networkError = self as? NetworkError {
            switch networkError {
            case .invalidStatusCode(let code, let body):
                if code == 401 {
                    return "로그인이 필요합니다.\n다시 로그인해주세요."
                } else if code == 403 {
                    return "권한이 없습니다.\n관리자에게 문의해주세요."
                } else if code == 404 {
                    return "요청한 정보를 찾을 수 없습니다."
                } else if code == 500 {
                    return "서버에 문제가 발생했습니다.\n잠시 후 다시 시도해주세요."
                } else if code >= 500 {
                    return "서버에 문제가 발생했습니다.\n잠시 후 다시 시도해주세요."
                } else {
                    return "요청 처리 중 오류가 발생했습니다.\n다시 시도해주세요."
                }
            case .invalidResponse:
                return "서버 응답을 처리할 수 없습니다.\n다시 시도해주세요."
            case .invalidURL:
                return "잘못된 요청입니다.\n앱을 다시 시작해주세요."
            }
        }
        
        // URLError 처리
        if let urlError = self as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "인터넷 연결을 확인해주세요."
            case .timedOut:
                return "요청 시간이 초과되었습니다.\n다시 시도해주세요."
            case .cannotFindHost, .cannotConnectToHost:
                return "서버에 연결할 수 없습니다.\n인터넷 연결을 확인해주세요."
            case .badServerResponse:
                return "서버 응답에 문제가 있습니다.\n잠시 후 다시 시도해주세요."
            default:
                return "네트워크 오류가 발생했습니다.\n다시 시도해주세요."
            }
        }
        
        // DecodingError 처리
        if self is DecodingError {
            return "데이터를 처리하는 중 오류가 발생했습니다.\n다시 시도해주세요."
        }
        
        // LocalizedError가 있는 경우
        if let localizedError = self as? LocalizedError,
           let errorDescription = localizedError.errorDescription {
            return errorDescription
        }
        
        // 기본 메시지
        return "오류가 발생했습니다.\n다시 시도해주세요."
    }
}
