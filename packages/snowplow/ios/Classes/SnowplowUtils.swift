import Foundation
import SnowplowTracker

class SnowplowUtils {
    static func trackScreenViewWithTracker(with tracker: SPTracker, andScreenName screenName: String) {
        let event = SPScreenView.build({ (builder : SPScreenViewBuilder?) -> Void in
            builder!.setName(screenName)
        })
        tracker.trackScreenViewEvent(event)
    }

    static func trackStructuredEventWithTracker(with tracker: SPTracker, andCategory category: String, andAction action: String, andLabel label: String, andProperty property: String) {
        let event = SPStructured.build({ (builder : SPStructuredBuilder?) -> Void in
            builder!.setCategory(category)
            builder!.setAction(action)
            builder!.setLabel(label)
            builder!.setProperty(property)
        })
        tracker.trackStructuredEvent(event)
    }

    static func trackCustomEventWithTracker(with tracker: SPTracker, andSchema customSchema: String, andData data: NSObject?) {
        let sdj = SPSelfDescribingJson(schema: customSchema, andData: data);

        let event = SPUnstructured.build({ (builder : SPUnstructuredBuilder?) -> Void in
            builder!.setEventData(sdj!)
        })
        tracker.trackUnstructuredEvent(event)
    }
}
