import Foundation
import SnowplowTracker

class SnowplowTrackerBuilder: NSObject, RequestCallback {
    let kNamespace = "sm"
    let kAppId     = "1"
    
    func getTracker(_ url: String) -> TrackerController {
        var configurations : [Configuration] = []
        
        let networkConfig = NetworkConfiguration(endpoint: url, method: .post)
        
        configurations.append(networkConfig)
        
        let trackerConfiguration = TrackerConfiguration()
            .appId(kAppId)
            .base64Encoding(true)
            .sessionContext(true)
            .platformContext(true)
            .lifecycleAutotracking(true)
            .screenViewAutotracking(true)
            .screenContext(true)
            .applicationContext(true)
            .exceptionAutotracking(true)
            .installAutotracking(true)
        
        configurations.append(trackerConfiguration)
        
        let emitterConfiguration = EmitterConfiguration()
        emitterConfiguration.requestCallback = self
        
        configurations.append(emitterConfiguration)
    
        if #available(iOS 10, *) {
            let sessionConfiguration = SessionConfiguration(foregroundTimeout: Measurement(value: 30, unit: .seconds), backgroundTimeout: Measurement(value: 30, unit: .seconds))
            configurations.append(sessionConfiguration)
        } else {
            // Fallback on earlier versions
        }
        
        let subjectConfiguration = SubjectConfiguration()
        
        configurations.append(subjectConfiguration)
        
        return Snowplow.createTracker(namespace: kNamespace, network: networkConfig, configurations: configurations)
    }
        
    func onSuccess(withCount successCount: Int) {
        print("Success: \(successCount)")
    }
    
    func onFailure(withCount failureCount: Int, successCount: Int) {
        print("Failure: \(failureCount), Success: \(successCount)")
    }  
}
