import 'dart:core';

extension MapParseInt on Map<dynamic, dynamic> {
  int parseToInt(String key) {
    if (!this.containsKey(key)) {
      return -1;
    }
    if (this[key] is! int) {
      try {
        return int.parse(this[key] as String);
      } catch (er) {
        return -1;
      }
    }
    return this[key];
  }
}
