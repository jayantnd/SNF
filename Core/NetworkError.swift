//
//  NetworkError.swift
//  SNF
//
//  Created by Jayant Dash on 1/10/19.
//  Copyright © 2019 Jayant Dash. All rights reserved.
//

import Foundation


//https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes
public struct NetworkError: Error, Equatable, Hashable {
    private init() {}
    
    public static let invalidMockFile = NSError(domain: "com.snf.network.error",
                                          code: -900001,
                                          userInfo: [NSDebugDescriptionErrorKey: "invalid mock file"]) as Error
    
    public static let loginRequired = NSError(domain: "com.snf.network.error",
                                          code: -900002,
                                          userInfo: [NSDebugDescriptionErrorKey: "login required"]) as Error
    public static let dataParsingError = NSError(domain: "com.snf.network.error",
                                          code: -900003,
                                          userInfo: [NSDebugDescriptionErrorKey: "response data parsing error"]) as Error
}
