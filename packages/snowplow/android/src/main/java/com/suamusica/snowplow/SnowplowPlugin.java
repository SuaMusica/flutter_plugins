package com.suamusica.snowplow;

import com.snowplowanalytics.snowplow.tracker.Subject;
import com.snowplowanalytics.snowplow.tracker.Tracker;
import com.snowplowanalytics.snowplow.tracker.events.SelfDescribing;
import com.snowplowanalytics.snowplow.tracker.events.Structured;
import com.snowplowanalytics.snowplow.tracker.payload.SelfDescribingJson;
import com.snowplowanalytics.snowplow.tracker.events.ScreenView;

import android.content.Context;
import android.util.Log;

import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;

import androidx.annotation.NonNull;

import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

/**
 * SnowplowPlugin
 */
public class SnowplowPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String CHANNEL_NAME = "com.suamusica.br/snowplow";
    private MethodChannel channel;
    private SnowplowTrackerBuilder stb;
    private Tracker tracker;
    private Context applicationContext;

    public SnowplowPlugin() {
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        applicationContext = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        stb = new SnowplowTrackerBuilder();
        tracker = stb.getTracker(applicationContext);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall methodCall, final MethodChannel.Result result) {
        switch (methodCall.method) {
            case "trackPageview":
                final String screenName = methodCall.argument("screenName");
                trackPageView(result, screenName);
                break;
            case "setUserId":
                final String userId = methodCall.argument("userId");
                setUserId(result, userId);
                break;
            case "trackCustomEvent":
                final String customScheme = methodCall.argument("customScheme");
                final Map<String, Object> eventMap = methodCall.argument("eventMap");
                trackCustomEvent(result, customScheme, eventMap);
                break;
            case "trackEvent":
                final String category = methodCall.argument("category");
                final String action = methodCall.argument("action");
                final String label = methodCall.argument("label");
                final String property = methodCall.argument("property");
                final String pageName = methodCall.argument("pageName");
                final Integer value = methodCall.argument("value");
                trackEvent(result, category, action, label, property, value, pageName);
                break;
            default:
                result.notImplemented();
        }
    }


    private void trackPageView(final MethodChannel.Result result, String screenName) {
        tracker.track(ScreenView.builder().name(screenName)
                .id(UUID.nameUUIDFromBytes(screenName.getBytes()).toString()).build());
        result.success(true);
    }

    private void trackEvent(final MethodChannel.Result result, String category, String action,
                            String label, String property, Integer value, String pageName) {

        Structured.Builder struct =
                Structured.builder().category(category).action(action).label(label).property(property);
        if (value > 0) {
            struct.value(Double.valueOf(value));
        }
        if (pageName != "") {
            List<SelfDescribingJson> contexts = new ArrayList<>();
            Map<String, Object> eventMap = new HashMap<>();
            eventMap.put("name", pageName);
            eventMap.put("id", UUID.nameUUIDFromBytes(pageName.getBytes()).toString());
            // Create your event data
            contexts.add(new SelfDescribingJson(
                    "iglu:com.snowplowanalytics.mobile/screen/jsonschema/1-0-0", eventMap));
            struct.customContext(contexts);
        }
        tracker.track(struct.build());
        result.success(true);
    }

    private void trackCustomEvent(final MethodChannel.Result result, String customScheme,
                                  Map<String, Object> eventMap) {
        SelfDescribingJson eventData = new SelfDescribingJson(customScheme, eventMap);
        List<SelfDescribingJson> contexts = new ArrayList<>();
        contexts.add(eventData);
        tracker.track(SelfDescribing.builder().eventData(eventData).customContext(contexts).build());
        result.success(true);
    }

    private void setUserId(final MethodChannel.Result result, String userId) {
        Subject sbj = tracker.getSubject();
        sbj.setUserId(userId);
        tracker.setSubject(sbj);
        result.success(true);
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        applicationContext = null;

    }
}
