//
//  SmadsCallback.swift
//  smads
//
//  Created by Alan Trope on 29/06/22.
//

import Foundation
public class SmadsCallback: NSObject {
    private var channel: FlutterMethodChannel
    let ON_AD_EVENT_METHOD = "onAdEvent"
    let ON_COMPLETE_METHOD = "onComplete"
    let ON_ERROR_METHOD = "onError"
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }
    
    public func onAdEvent(args:[String : String]) {
        if (args["type"] != "AD_PROGRESS") {
            print("AD: onAdEvent:: \(args)")
        }

        channel.invokeMethod(ON_AD_EVENT_METHOD, arguments: args)
    }
    
    public func onComplete() {
        print("AD: onComplete()")
        channel.invokeMethod(ON_COMPLETE_METHOD,arguments: [])
    }
    
    public func onError(args:[String : String?]) {
        print("AD: onError()")
        onAdEvent(args: ["type" : "ERROR"])
        channel.invokeMethod(ON_ERROR_METHOD, arguments: args)
    }
    
    
    
    
}
