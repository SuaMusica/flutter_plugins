package com.suamusica.snowplow;

import com.snowplowanalytics.snowplow.tracker.Subject;
import com.snowplowanalytics.snowplow.tracker.Tracker;
import com.snowplowanalytics.snowplow.tracker.events.SelfDescribing;
import com.snowplowanalytics.snowplow.tracker.payload.SelfDescribingJson;
import com.snowplowanalytics.snowplow.tracker.events.ScreenView;
import android.content.Context;
import java.util.Map;
import androidx.annotation.NonNull;

import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** SnowplowPlugin */
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
    channel =
        new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), CHANNEL_NAME);
    stb = new SnowplowTrackerBuilder();
    tracker = stb.getTracker(applicationContext);
    channel.setMethodCallHandler(this);
  }

  private SnowplowPlugin(Context context) {
    this.applicationContext = context;
    this.stb = new SnowplowTrackerBuilder();
    this.tracker = this.stb.getTracker(this.applicationContext);
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(new SnowplowPlugin(registrar.context()));
  }

  @Override
  public void onMethodCall(MethodCall methodCall, final MethodChannel.Result result) {
    switch (methodCall.method) {
      case "trackPageview":
        final String screenName = methodCall.argument("screenName");
        trackPageview(result, screenName);
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

      default:
        result.notImplemented();
    }
  }


  private void trackPageview(final MethodChannel.Result result, String screenName) {
    tracker.track(ScreenView.builder().name(screenName)
        .id(UUID.nameUUIDFromBytes(screenName.getBytes()).toString()).build());
    result.success(true);
  }

  private void trackCustomEvent(final MethodChannel.Result result, String customScheme,
      Map<String, Object> eventMap) {
    SelfDescribingJson eventData = new SelfDescribingJson(customScheme, eventMap);
    tracker.track(SelfDescribing.builder().eventData(eventData).build());
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
