//
//  NetworkRequest.swift
//  SNF
//
//  Created by Jayant Dash on 10/1/18.
//  Copyright © 2018 Jayant Dash. All rights reserved.
//

import Foundation


public protocol NetworkRequest {
    func mockFile() -> String?
    
    func retryCount() -> Int
    
    func shouldRetry(statusCode: Int) -> Bool
    
    func shouldRetry(error: Error?) -> Bool
    
    func shouldAdpat() -> Bool
    
    func shouldCheck() -> Bool
    
    func shouldPinCertificate() -> Bool
    
    func shouldIntercept() -> Bool
    
    func shoudlRefreshToken() -> Bool
               
    func saveData<T:Codable>(model: T, networkResponse: NetworkResponse)

    func fetchData<T:Codable>(completion: @escaping ((_ dataModel: T? , _ networkResponse: NetworkResponse) -> Void))
    
    func request() -> URLRequest
}

extension NetworkRequest {

    func saveData<T:Codable>(model: T, networkResponse: NetworkResponse) {}

    func fetchData<T:Codable>(completion: @escaping ((_ dataModel: T? , _ networkResponse: NetworkResponse) -> Void)) {}
}
