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
                let id = UUID(name: pagename, namespace: UUID.DNS, version: .v3)
                print("TESTE2" + "pagename: " + pagename + " id: " + id.uuidString);
                let data : [String:Any] = ["name": pagename, "id": id.uuidString]
                let eventData = SPSelfDescribingJson(schema: "iglu:com.snowplowanalytics.mobile/screen/jsonschema/1-0-0", andData: data as NSObject?)
                var contexts: [SPSelfDescribingJson] = []
                contexts.append(eventData!)
                builder!.setContexts(NSMutableArray(array: contexts))
            }
//            //################
//            if (pageName != "") {
//            Log.i("TESTE2", "pagename: "+ pageName);
//            tracker.getScreenState().updateScreenState(UUID.nameUUIDFromBytes(pageName.getBytes()).toString(), pageName, "", "");
//        }
            //################
            
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
