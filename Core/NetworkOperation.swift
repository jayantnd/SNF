//
//  NetworkOperation.swift
//  SNF
//
//  Created by Jayant Dash on 10/1/18.
//  Copyright © 2018 Jayant Dash. All rights reserved.
//

import Foundation


public class NetworkOperation : BaseOperation {
    private var task: URLSessionTask?
    private let networkRequest: NetworkRequest
    private var completion: ((NetworkResponse) -> Void)?
    private var retryCount = 0
    private static var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Snf.requestTimeOut
        configuration.timeoutIntervalForResource = Snf.resourseTimeOut
        configuration.httpAdditionalHeaders = Snf.httpAdditionalHeaders
        if !Snf.shouldURLCache {
            configuration.urlCache = nil
            configuration.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        }
        return URLSession(configuration: configuration)
    }()

    private var startTime = Date()
    
    internal init(request: NetworkRequest, completion: ((NetworkResponse) -> Void)?) {
        networkRequest = request
        super.init()
        self.completion = completion
    }
    
    override public func cancel() {
        task?.cancel()
        finish()
        super.cancel()
    }
    
    override internal func execute() {
        startTime = Date()
        if let mockJsonFile = networkRequest.mockFile() {
            do {
                if let fileURL = Bundle.main.url(forResource: mockJsonFile, withExtension: "") {
                    let fileData = try Data(contentsOf: fileURL)
                    usleep(useconds_t(Snf.mockResponseTime * 1000000))
                    self.handleResponse(networkResponse: NetworkResponse(data: fileData, statusCode: 200))
                } else {
                    usleep(useconds_t(Snf.mockResponseTime * 1000000))
                    self.handleResponse(networkResponse: NetworkResponse(statusCode: 200))
                }
            } catch {
                handleResponse(networkResponse: NetworkResponse(error: NetworkError.invalidMockFile))
            }
        } else {
            checkRequest(request: networkRequest.request())
        }
    }
    
    private func checkRequest(request: URLRequest) {

        if let requestChecker = Snf.requestChecker, networkRequest.shouldCheck() {
            requestChecker.check(request: request) {[unowned self] (shouldProceed, networkResponse) in
                if shouldProceed {
                    self.prepareRequest(request: request)
                } else {
                    self.handleResponse(networkResponse: networkResponse)
                }
            }
        } else {
            prepareRequest(request: request)
        }
    }
    
    private func prepareRequest(request: URLRequest) {

        var urlRequest = request
        if let adapter = Snf.requestAdapter, networkRequest.shouldAdpat() {
            urlRequest = adapter.adapt(request)
        }
        sendRequest(request: urlRequest)
    }
    
    private func sendRequest(request: URLRequest) {

        task = NetworkOperation.urlSession.dataTask(with: request, completionHandler: {[unowned self](data, response, error) in
            let networkResponse = NetworkResponse(data: data, response: response, error: error)
            if let networkLogger = Snf.responseLogger {
                networkLogger.Log(urlRequest: request,
                                         networkResponse: networkResponse,
                                         startTime: self.startTime, endTime: Date())
            }
            
            if self.networkRequest.shouldRetry(statusCode: networkResponse.statusCode),
               self.networkRequest.shouldRetry(error: networkResponse.error),
                let retrier = Snf.requestRetrier,
                self.retryCount < self.networkRequest.retryCount() {
                
                self.retryCount += 1
                retrier.retry(request: request, networkResponse: networkResponse, completion: {(shouldRetry, timeDelay, networkResponse) in
                    if shouldRetry {
                        usleep(useconds_t(timeDelay * 1000000))
                        self.execute()
                    } else {
                        self.handleResponse(networkResponse: networkResponse)
                    }
                })
            } else {
                self.handleResponse(networkResponse: networkResponse)
            }
        })
        if isCancelled {
            cancel()
        }
        task?.resume()
    }
    
    private func handleResponse(networkResponse: NetworkResponse) {
        completion?(networkResponse)
        finish()
    }
}
