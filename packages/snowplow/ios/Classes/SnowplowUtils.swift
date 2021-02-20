import Foundation
import SnowplowTracker
import UUIDNamespaces
class SnowplowUtils {
    static func trackScreenViewWithTracker(with tracker: SPTracker, andScreenName screenName: String) {
        let event = SPScreenView.build({ (builder : SPScreenViewBuilder?) -> Void in
            builder!.setName(screenName)
        })
        tracker.track(event)
    }

    static func trackStructuredEventWithTracker(with tracker: SPTracker, andCategory category: String, andAction action: String, andLabel label: String,  andProperty property: String,andValue value: Int, andPagename pagename: String) {
        let event = SPStructured.build({ (builder : SPStructuredBuilder?) -> Void in
            builder!.setCategory(category)
            builder!.setAction(action)
            builder!.setLabel(label)
            if(value>0){
                builder!.setValue(Double(value))
            }
            if(pagename != ""){
                //We have no way of updating pageName without a pageview on iOS.
                trackScreenViewWithTracker(with: tracker, andScreenName: pagename)
            }
            builder!.setProperty(property)
        })
        tracker.track(event)
    }

    static func trackCustomEventWithTracker(with tracker: SPTracker, andSchema customSchema: String, andData data: NSObject) {
        let eventData = SPSelfDescribingJson(schema: customSchema, andData: data);
        var contexts: [SPSelfDescribingJson] = []
        contexts.append(eventData!)
        let event = SPUnstructured.build({ (builder : SPUnstructuredBuilder?) -> Void in
            builder!.setEventData(eventData ?? SPSelfDescribingJson(schema: customSchema, andData: data))
            builder!.setContexts(NSMutableArray(array: contexts))
        })
        tracker.track(event)
    }
}
