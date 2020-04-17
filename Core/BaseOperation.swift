//
//  BaseOperation.swift
//  SNF
//
//  Created by Jayant Dash on 10/1/18.
//  Copyright © 2018 Jayant Dash. All rights reserved.
//

import Foundation


@objc private enum OperationState: Int {
    case ready
    case executing
    case finished
}

public class BaseOperation: Operation {
    
    internal override init() {
        super.init()
    }
    
    private let stateQueue = DispatchQueue(label: "snf.operation.state", attributes: .concurrent)
    
    private var rawState = OperationState.ready
    
    @objc private dynamic var state: OperationState {
        get {
            return stateQueue.sync(execute: { rawState })
        } set {
            willChangeValue(forKey: "state")
            stateQueue.sync(
                flags: .barrier,
                execute: { rawState = newValue })
            didChangeValue(forKey: "state")
        }
    }
    
    final override public var isReady: Bool {
        return state == .ready && super.isReady
    }
    
    public final override var isExecuting: Bool {
        return state == .executing
    }
    
    public final override var isFinished: Bool {
        return state == .finished
    }
    
    public final override var isAsynchronous: Bool {
        return true
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return ["state"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return ["state"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return ["state"]
    }
    
    public override final func start() {
        if isCancelled {
            finish()
            return
        }
        
        state = .executing
        
        execute()
    }
    
    internal func execute() {
        fatalError("Subclasses must implement this to perform background work and must not call this method with super")
    }
    
    /// Call this function after any work is done or after a call to `cancel()` to move the operation into a completed state.
    internal final func finish() {
        state = .finished
    }
    
    public override func cancel() {
        finish()
        super.cancel()
    }
}
