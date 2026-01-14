//
//  BaseURL.swift
//  Damago
//
//  Created by 김재영 on 1/6/26.
//

import Foundation

public enum BaseURL {
    public static var string: String {
        #if DEBUG
        // Local Emulator
        if let localIP = ProcessInfo.processInfo.environment["USE_LOCAL_EMULATOR"] {
            return "http://\(localIP):5001/damago-dev-26/us-central1"
        }

        // DEV
        return "https://us-central1-damago-dev-26.cloudfunctions.net"
        #else
        // PROD
        return "https://us-central1-damago-a43da.cloudfunctions.net"
        #endif
    }
}
