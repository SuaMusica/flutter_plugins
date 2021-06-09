import Foundation
import SnowplowTracker

class SnowplowUtils {
    static func trackScreenViewWithTracker(with tracker: TrackerController, andUserId userId: String, andScreenName screenName: String) {
        tracker.subject!.userId = userId
        let event = ScreenView(name: screenName, screenId: UUID.init())
        tracker.track(event)
    }

    static func trackStructuredEventWithTracker(with tracker: TrackerController, andUserId userId: String, andCategory category: String, andAction action: String, andLabel label: String,  andProperty property: String, andValue value: Int, andPagename pagename: String) {
        let event = Structured(category: category, action: action)
        event.label = label
        if value > 0 {
            event.value = NSNumber(value: value)
        }
        event.property = property
        tracker.subject!.userId = userId
        tracker.track(event)
    }

    static func trackCustomEventWithTracker(with tracker: TrackerController, andUserId userId: String, andSchema customSchema: String, andData data: NSObject) {
        let eventData = SelfDescribingJson(schema: customSchema, andData: data);
        let event = SelfDescribing(eventData: eventData!)
        tracker.subject!.userId = userId
        tracker.track(event)
    }
}
