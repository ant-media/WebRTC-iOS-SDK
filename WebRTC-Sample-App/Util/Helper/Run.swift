//
//  Run.swift
//  AntMediaReferenceApplication
//
//  Created by Oğulcan on 18.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation

open class Run {

    @discardableResult
    open class func afterDelay(_ delayInSeconds: Double, block: @escaping ()->()) -> SimpleClosure? {
        var cancelled = false
        
        let cancelClosure: SimpleClosure = {
            cancelled = true
        }
        
        let time = DispatchTime.now() + Double(Int64(delayInSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time) { () -> Void in
            if !cancelled {
                block()
            }
        }
        
        return cancelClosure
    }
    
    open class func onMainThread(_ block: @escaping ()->()) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) { () -> Void in
            block()
        }
    }
}
