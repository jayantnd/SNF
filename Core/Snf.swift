//
//  Snf.swift
//  SNF
//
//  Created by Jayant Dash on 9/16/18.
//  Copyright © 2018 Jayant Dash. All rights reserved.
//

import Foundation


public protocol SnfResponseLogger {
    func Log(urlRequest: URLRequest, networkResponse: NetworkResponse, startTime:Date, endTime: Date)
}

public protocol SnfRequestAdapter {
    func adapt(_ urlRequest: URLRequest) -> URLRequest
}

public protocol SnfRequestRetrier {
    typealias RetrierCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval, _ networkResponse: NetworkResponse) -> Void
    func retry(request: URLRequest, networkResponse: NetworkResponse, completion: @escaping RetrierCompletion)
}

public protocol SnfRequestChecker {
    typealias CheckerCompletion = (_ shouldProceed: Bool, _ networkResponse: NetworkResponse) -> Void
    func check(request: URLRequest, completion: @escaping CheckerCompletion)
}

public protocol SnfResponseIntercepter {
    typealias IntercepterCompletion = (_ networkResponse: NetworkResponse) -> Void
    func intercept(request: URLRequest, networkResponse: NetworkResponse, completion: @escaping IntercepterCompletion)
}

public protocol SnfTokenRefresher {
    func request() -> NetworkRequest
    func OAuth2Details() -> (clientID: String, clientSecret: String, accessToken: String, refreshToken: String, expiryTime: Date)
    func response(response: NetworkResponse)
}

public protocol SnfSSLPinning {
    func certificate(request: URLRequest) -> Data?
    func publicKey(request: URLRequest) -> String?
    func MD5Hash(request: URLRequest) -> String?
}

open class Snf {
    public static var responseLogger: SnfResponseLogger?
    public static var requestAdapter: SnfRequestAdapter?
    public static var requestRetrier: SnfRequestRetrier?
    public static var requestChecker: SnfRequestChecker?
    public static var responseIntercepter: SnfResponseIntercepter?

    private static var maxConcurrentOperation = 100
    public static var requestTimeOut: TimeInterval = 60.0
    public static var resourseTimeOut: TimeInterval = 120.0
    public static var shouldURLCache: Bool = true
    public static var mockResponseTime: TimeInterval = 1.0
    private static var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = maxConcurrentOperation
        return queue
    }()
    public static var httpAdditionalHeaders:[AnyHashable : Any]?  = nil

    private init() {}
}

extension Snf {
    
    public static func cancelAllOperations() {
        Snf.operationQueue.cancelAllOperations()
    }
    
    public static func pauseAllOperations() {
        Snf.operationQueue.isSuspended = true
    }
    
    public static func resumeAllOperations() {
        Snf.operationQueue.isSuspended = false
    }
}

extension Snf {
    public static func send(networkRequest: NetworkRequest,
                            completion: ((_ data: Data?, NetworkResponse) -> Void)? = nil) -> NetworkOperation {
        let operation = NetworkOperation(request: networkRequest) { (networkResponse) in
            networkResponse.dataSource = .fromNetwork
            if let intercepter = responseIntercepter {
                intercepter.intercept(request: networkRequest.request(), networkResponse: networkResponse) { (networkResponse) in
                    completion?(networkResponse.data, networkResponse)
                }
            } else {
                completion?(networkResponse.data, networkResponse)
            }
        }
        Snf.operationQueue.addOperation(operation)
        return operation
    }
}

extension Snf {
    public static func send(networkRequest: NetworkRequest,
                            completion: @escaping (_ data: Data?, NetworkResponse) -> Void) -> NetworkOperation {
        networkRequest.fetchData(completion: completion)
        let operation = NetworkOperation(request: networkRequest) { (networkResponse) in
            networkResponse.dataSource = .fromNetwork
            // saveData function will call on network error also. so Network request class need to decide to save or not
            networkRequest.saveData(model: networkResponse.data, networkResponse: networkResponse)
            if let intercepter = responseIntercepter {
                intercepter.intercept(request: networkRequest.request(), networkResponse: networkResponse) { (networkResponse) in
                    completion(networkResponse.data, networkResponse)
                }
            } else {
                completion(networkResponse.data, networkResponse)
            }
        }
        Snf.operationQueue.addOperation(operation)
        return operation
    }
}

extension Snf {
    public static func send<T:Codable>(modelType: T.Type, networkRequest: NetworkRequest,
                                       completion: @escaping ((_ dataModel: T? , NetworkResponse) -> Void)) -> NetworkOperation {
        networkRequest.fetchData(completion: completion)
        let operation = NetworkOperation(request: networkRequest) { (networkResponse) in
            networkResponse.dataSource = .fromNetwork
            if let data = networkResponse.data {
                if let model = try? JSONDecoder().decode(modelType, from: data) {
                    networkRequest.saveData(model: model, networkResponse: networkResponse)
                    if let intercepter = responseIntercepter {
                        intercepter.intercept(request: networkRequest.request(), networkResponse: networkResponse) { (networkResponse) in
                            completion(model, networkResponse)
                        }
                    } else {
                        completion(model, networkResponse)
                    }
                } else {
                    networkResponse.error = NetworkError.dataParsingError
                    if let intercepter = responseIntercepter {
                        intercepter.intercept(request: networkRequest.request(), networkResponse: networkResponse) { (networkResponse) in
                            completion(nil, networkResponse)
                        }
                    } else {
                        completion(nil, networkResponse)
                    }
                }
            } else {
                if let intercepter = responseIntercepter {
                    intercepter.intercept(request: networkRequest.request(), networkResponse: networkResponse) { (networkResponse) in
                        completion(nil, networkResponse)
                    }
                } else {
                    completion(nil, networkResponse)
                }
            }
        }
        Snf.operationQueue.addOperation(operation)
        return operation
    }
}
