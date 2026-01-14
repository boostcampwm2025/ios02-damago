//
//  BaseURL.swift
//  Damago
//
//  Created by 김재영 on 1/6/26.
//

import Foundation

public enum BaseURL {
    public static var string: String {
        if let localIP = ProcessInfo.processInfo.environment["USE_LOCAL_EMULATOR"] {
            return "http://\(localIP):5001/damago-a43da/us-central1"
        }
        
        return "https://us-central1-damago-a43da.cloudfunctions.net"
    }
}
