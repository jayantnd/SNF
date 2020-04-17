//
//  HttpMethod.swift
//  SNF
//
//  Created by Jayant Dash on 9/18/18.
//  Copyright © 2018 Jayant Dash. All rights reserved.
//

import Foundation


public struct HTTPMethod: Equatable, Hashable {

    private init() {}
    
    public static let get = "GET"
    public static let put = "PUT"
    public static let post = "POST"
    public static let delete = "DELETE"
    public static let head = "HEAD"
    public static let options = "OPTIONS"
    public static let trace = "TRACE"
    public static let connect = "CONNECT"
}
