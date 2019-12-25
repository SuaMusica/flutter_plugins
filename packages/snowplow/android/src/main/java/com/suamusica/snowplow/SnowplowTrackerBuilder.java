
package com.suamusica.snowplow;

import com.snowplowanalytics.snowplow.tracker.*;
import android.content.Context;

public class SnowplowTrackerBuilder {
    public static Tracker getTracker(Context context) {
        Emitter emitter = getEmitter(context);
        Subject subject = getSubject(context); // Optional
        return Tracker.init(new Tracker.TrackerBuilder(emitter, "sm", "1", context)
            .subject(subject) // Optional
            .build()
        );
    }
    private static Emitter getEmitter(Context context) {
        return new Emitter.EmitterBuilder("snowplow.suamusica.com.br", context).build();
    }
    private static Subject getSubject(Context context) {
        return new Subject.SubjectBuilder()
            .context(context)
            .build();
    }
}
