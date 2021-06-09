package com.suamusica.snowplow;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.snowplowanalytics.snowplow.Snowplow;
import com.snowplowanalytics.snowplow.controller.SubjectController;
import com.snowplowanalytics.snowplow.controller.TrackerController;
import com.snowplowanalytics.snowplow.event.Event;
import com.snowplowanalytics.snowplow.event.ScreenView;
import com.snowplowanalytics.snowplow.event.SelfDescribing;
import com.snowplowanalytics.snowplow.event.Structured;
import com.snowplowanalytics.snowplow.globalcontexts.GlobalContext;
import com.snowplowanalytics.snowplow.payload.SelfDescribingJson;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
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
    private TrackerController tracker;
    private Context applicationContext;
    private String userId = "0";
    public SnowplowPlugin() {
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        applicationContext = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        tracker = new SnowplowTrackerBuilder().getTracker(applicationContext);
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
        tracker.getSubject().setUserId(userId);
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
        if (!pageName.equals("")) {
            // TODO: (nferreira) find a way to implement this.
            // Now this implemented as an package internal thing that we do not have access to it
            //tracker.getScreenState().updateScreenState(UUID.nameUUIDFromBytes(pageName.getBytes()).toString(), pageName, "", "");
        }
        tracker.getSubject().setUserId(userId);
        tracker.track(struct.build());
        result.success(true);
    }

    private void trackCustomEvent(final MethodChannel.Result result, String customScheme,
                                  Map<String, Object> eventMap) {
        SelfDescribingJson eventData = new SelfDescribingJson(customScheme, eventMap);
        tracker.getSubject().setUserId(userId);
        final SelfDescribing event = new SelfDescribing(eventData);
        event.customContexts.add(eventData);
        tracker.track(event);
        result.success(true);
    }

    private void setUserId(final MethodChannel.Result result, String userId) {
        this.userId = userId;
        result.success(true);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        applicationContext = null;
    }
}
