import Foundation
import SnowplowTracker

class SnowplowUtils {
    static func trackScreenViewWithTracker(_ tracker: SPTracker, _ screenName: String) {
        let event = SPScreenView.build({ (builder : SPScreenViewBuilder?) -> Void in
            builder!.setName(screenName)
        })
        tracker.trackScreenViewEvent(event)
    }
}
