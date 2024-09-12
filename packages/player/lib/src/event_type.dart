enum EventType {
  PLAY_REQUESTED,
  PLAY_NOTIFICATION,
  BEFORE_PLAY,
  SET_CURRENT_MEDIA_INDEX,
  BUFFERING,
  PLAYING,
  PAUSE_REQUEST,
  PAUSED,
  PAUSED_NOTIFICATION,
  RESUME_REQUESTED,
  RESUMED,
  STOP_REQUESTED,
  STOPPED,
  RELEASE_REQUESTED,
  RELEASED,
  DURATION_CHANGE,
  POSITION_CHANGE,
  REWIND,
  PREVIOUS,
  PREVIOUS_NOTIFICATION,
  FORWARD,
  TOGGLE_PLAY_PAUSE,
  NEXT,
  NEXT_NOTIFICATION,
  FINISHED_PLAYING,
  ERROR_OCCURED,
  NETWORK_CHANGE,
  SEEK_START,
  SEEK_END,
  BUFFER_EMPTY,
  EXTERNAL_RESUME_REQUESTED,
  EXTERNAL_PAUSE_REQUESTED,
  FAVORITE_MUSIC,
  UNFAVORITE_MUSIC,
  ITEM_TRANSITION,
  REPEAT_CHANGED,
  SHUFFLE_CHANGED,
}

enum PlayerErrorType {
  FAILED,
  UNKNOWN,
  UNDEFINED,
  FAILED_TO_PLAY,
  FAILED_TO_PLAY_ERROR,
  NETWORK_ERROR,
  INFORMATION,
  PERMISSION_DENIED,
}

extension FeedTypeString on PlayerErrorType {
  String get toShortString =>
      this.toString().replaceAll("PlayerErrorType.", "");
}
