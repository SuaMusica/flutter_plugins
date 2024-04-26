enum AdEventType {
  ALL_ADS_COMPLETED,
  CLICKED,
  COMPLETE,
  CUEPOINTS_CHANGED,
  FIRST_QUARTILE,
  LOG,
  AD_BREAK_READY,
  MIDPOINT,
  PAUSE,
  RESUME,
  SKIPPED,
  STARTED,
  TAPPED,
  THIRD_QUARTILE,
  LOADED,
  AD_BREAK_STARTED,
  AD_BREAK_ENDED,
  AD_PERIOD_STARTED,
  AD_PERIOD_ENDED,
  ERROR,
}

extension AdEventTypeX on AdEventType {
  String toShortString() {
    switch (this) {
      case AdEventType.ALL_ADS_COMPLETED:
        return "ALL_ADS_COMPLETED";
      case AdEventType.CLICKED:
        return "CLICKED";
      case AdEventType.COMPLETE:
        return "COMPLETE";
      case AdEventType.CUEPOINTS_CHANGED:
        return "CUEPOINTS_CHANGED";
      case AdEventType.FIRST_QUARTILE:
        return "FIRST_QUARTILE";
      case AdEventType.LOG:
        return "LOG";
      case AdEventType.AD_BREAK_READY:
        return "AD_BREAK_READY";
      case AdEventType.MIDPOINT:
        return "MIDPOINT";
      case AdEventType.PAUSE:
        return "PAUSE";
      case AdEventType.RESUME:
        return "RESUME";
      case AdEventType.SKIPPED:
        return "SKIPPED";
      case AdEventType.STARTED:
        return "STARTED";
      case AdEventType.TAPPED:
        return "TAPPED";
      case AdEventType.THIRD_QUARTILE:
        return "THIRD_QUARTILE";
      case AdEventType.LOADED:
        return "LOADED";
      case AdEventType.AD_BREAK_STARTED:
        return "AD_BREAK_STARTED";
      case AdEventType.AD_BREAK_ENDED:
        return "AD_BREAK_ENDED";
      case AdEventType.AD_PERIOD_STARTED:
        return "AD_PERIOD_STARTED";
      case AdEventType.AD_PERIOD_ENDED:
        return "AD_PERIOD_ENDED";
      case AdEventType.ERROR:
        return "ERROR";
      default:
        return "Unknown";
    }
  }
}
