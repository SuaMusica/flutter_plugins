enum PreRollEvent {
  ALL_ADS_COMPLETED,
  CLICKED,
  COMPLETED,
  CUEPOINTS_CHANGED,
  CONTENT_PAUSE_REQUESTED,
  CONTENT_RESUME_REQUESTED,
  FIRST_QUARTILE,
  LOG,
  AD_BREAK_READY,
  MIDPOINT,
  PAUSED,
  RESUMED,
  SKIPPABLE_STATE_CHANGED,
  SKIPPED,
  STARTED,
  TAPPED,
  ICON_TAPPED,
  THIRD_QUARTILE,
  LOADED,
  AD_PROGRESS,
  AD_BUFFERING,
  AD_BREAK_STARTED,
  AD_BREAK_ENDED,
  AD_PERIOD_STARTED,
  AD_PERIOD_ENDED,
  UNKNOWN,
}

extension ParseToPreRollEvent on String {
  PreRollEvent toPreRollEvent() {
    switch (this) {
      case "ALL_ADS_COMPLETED":
        return PreRollEvent.ALL_ADS_COMPLETED;
      case "CLICKED":
        return PreRollEvent.CLICKED;
      case "COMPLETED":
        return PreRollEvent.COMPLETED;
      case "CUEPOINTS_CHANGED":
        return PreRollEvent.CUEPOINTS_CHANGED;
      case "CONTENT_PAUSE_REQUESTED":
        return PreRollEvent.CONTENT_PAUSE_REQUESTED;
      case "CONTENT_RESUME_REQUESTED":
        return PreRollEvent.CONTENT_RESUME_REQUESTED;
      case "FIRST_QUARTILE":
        return PreRollEvent.FIRST_QUARTILE;
      case "LOG":
        return PreRollEvent.LOG;
      case "AD_BREAK_READY":
        return PreRollEvent.AD_BREAK_READY;
      case "MIDPOINT":
        return PreRollEvent.MIDPOINT;
      case "PAUSED":
        return PreRollEvent.PAUSED;
      case "RESUMED":
        return PreRollEvent.RESUMED;
      case "SKIPPABLE_STATE_CHANGED":
        return PreRollEvent.SKIPPABLE_STATE_CHANGED;
      case "SKIPPED":
        return PreRollEvent.SKIPPED;
      case "STARTED":
        return PreRollEvent.STARTED;
      case "TAPPED":
        return PreRollEvent.TAPPED;
      case "ICON_TAPPED":
        return PreRollEvent.ICON_TAPPED;
      case "THIRD_QUARTILE":
        return PreRollEvent.THIRD_QUARTILE;
      case "LOADED":
        return PreRollEvent.LOADED;
      case "AD_PROGRESS":
        return PreRollEvent.AD_PROGRESS;
      case "AD_BUFFERING":
        return PreRollEvent.AD_BUFFERING;
      case "AD_BREAK_STARTED":
        return PreRollEvent.AD_BREAK_STARTED;
      case "AD_BREAK_ENDED":
        return PreRollEvent.AD_BREAK_ENDED;
      case "AD_PERIOD_STARTED":
        return PreRollEvent.AD_PERIOD_STARTED;
      case "AD_PERIOD_ENDED":
        return PreRollEvent.AD_PERIOD_ENDED;
      default:
        return PreRollEvent.UNKNOWN;
    }
  }
}

extension ParseToString on PreRollEvent {
  String toShortString() {
    switch (this) {
      case PreRollEvent.ALL_ADS_COMPLETED:
        return "ALL_ADS_COMPLETED";
      case PreRollEvent.CLICKED:
        return "CLICKED";
      case PreRollEvent.COMPLETED:
        return "COMPLETED";
      case PreRollEvent.CUEPOINTS_CHANGED:
        return "CUEPOINTS_CHANGED";
      case PreRollEvent.CONTENT_PAUSE_REQUESTED:
        return "CONTENT_PAUSE_REQUESTED";
      case PreRollEvent.CONTENT_RESUME_REQUESTED:
        return "CONTENT_RESUME_REQUESTED";
      case PreRollEvent.FIRST_QUARTILE:
        return "FIRST_QUARTILE";
      case PreRollEvent.LOG:
        return "LOG";
      case PreRollEvent.AD_BREAK_READY:
        return "AD_BREAK_READY";
      case PreRollEvent.MIDPOINT:
        return "MIDPOINT";
      case PreRollEvent.PAUSED:
        return "PAUSED";
      case PreRollEvent.RESUMED:
        return "RESUMED";
      case PreRollEvent.SKIPPABLE_STATE_CHANGED:
        return "SKIPPABLE_STATE_CHANGED";
      case PreRollEvent.SKIPPED:
        return "SKIPPED";
      case PreRollEvent.STARTED:
        return "STARTED";
      case PreRollEvent.TAPPED:
        return "TAPPED";
      case PreRollEvent.ICON_TAPPED:
        return "ICON_TAPPED";
      case PreRollEvent.THIRD_QUARTILE:
        return "THIRD_QUARTILE";
      case PreRollEvent.LOADED:
        return "LOADED";
      case PreRollEvent.AD_PROGRESS:
        return "AD_PROGRESS";
      case PreRollEvent.AD_BUFFERING:
        return "AD_BUFFERING";
      case PreRollEvent.AD_BREAK_STARTED:
        return "AD_BREAK_STARTED";
      case PreRollEvent.AD_BREAK_ENDED:
        return "AD_BREAK_ENDED";
      case PreRollEvent.AD_PERIOD_STARTED:
        return "AD_PERIOD_STARTED";
      case PreRollEvent.AD_PERIOD_ENDED:
        return "AD_PERIOD_ENDED";
      default:
        return "Unknown";
    }
  }
}
