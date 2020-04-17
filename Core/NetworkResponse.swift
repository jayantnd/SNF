//
//  NetworkResponse.swift
//  SNF
//
//  Created by Jayant Dash on 12/27/18.
//  Copyright © 2018 Jayant Dash. All rights reserved.
//

import Foundation


public enum DataSource: Int {
    case fromCache
    case fromNetwork
}

public class NetworkResponse {
    
    public private(set) var statusCode: Int = 0
    public private(set) var data: Data?
    public private(set) var response: URLResponse?
    public var error: Error?
    public var dataSource: DataSource = .fromCache
        
    public init(data: Data? = nil, response: URLResponse? = nil,
                dataSource: DataSource = .fromCache,
                error: Error? = nil, statusCode: Int = 0) {
        self.dataSource = dataSource
        self.response = response
        self.statusCode = (response as? HTTPURLResponse)?.statusCode ?? statusCode
        self.data = data
        self.error = error
    }
}
