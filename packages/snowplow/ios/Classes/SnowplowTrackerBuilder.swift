import Foundation
import SnowplowTracker

class SnowplowTrackerBuilder: NSObject, SPRequestCallback {    
    let kNamespace = "sm"
    let kAppId     = "1"
    
    func getTracker(_ url: String, method: SPRequestOptions, protocol _protocol: SPProtocol) -> SPTracker {
        let emitter = SPEmitter.build({ (builder : SPEmitterBuilder?) -> Void in
            builder!.setUrlEndpoint(url)
            builder!.setHttpMethod(method)
            builder!.setProtocol(_protocol)
            builder!.setCallback(self)
            builder!.setEmitRange(500)
            builder!.setEmitThreadPoolSize(20)
            builder!.setByteLimitPost(52000)
        })
        let subject = SPSubject(platformContext: true, andGeoContext: false)
        subject?.setUserId("0")
        let newTracker = SPTracker.build({ (builder : SPTrackerBuilder?) -> Void in
            builder!.setEmitter(emitter)
            builder!.setAppId(self.kAppId)
            builder!.setTrackerNamespace(self.kNamespace)
            builder!.setBase64Encoded(false)
            builder!.setSessionContext(true)
            builder!.setSubject(subject)
            builder!.setLifecycleEvents(true)
        })
        return newTracker!
    }
        
    func onSuccess(withCount successCount: Int) {
        print("Success: \(successCount)")
    }
    
    func onFailure(withCount failureCount: Int, successCount: Int) {
        print("Failure: \(failureCount), Success: \(successCount)")
    }  
}
