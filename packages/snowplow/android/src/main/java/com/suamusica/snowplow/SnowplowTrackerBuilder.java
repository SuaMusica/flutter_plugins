
package com.suamusica.snowplow;

import com.snowplowanalytics.snowplow.tracker.*;
import com.snowplowanalytics.snowplow.tracker.emitter.RequestSecurity;
import com.snowplowanalytics.snowplow.tracker.emitter.TLSVersion;
import com.snowplowanalytics.snowplow.tracker.utils.LogLevel;

import android.content.Context;

public class SnowplowTrackerBuilder {
    public static Tracker getTracker(Context context) {
        Emitter emitter = getEmitter(context);
        Subject subject = getSubject(context); // Optional
        subject.setUserId("0");
        return Tracker.init(new Tracker.TrackerBuilder(emitter, "sm", "1", context).subject(subject) // Optional
                .build());

    }

    private static Emitter getEmitter(Context context) {
        return new Emitter.EmitterBuilder("snowplow.suamusica.com.br", context)
                .security(RequestSecurity.HTTPS).build();
    }

    private static Subject getSubject(Context context) {
        return new Subject.SubjectBuilder().context(context).build();
    }
}
