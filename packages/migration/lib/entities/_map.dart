import 'dart:core';

extension MapParseInt on Map<dynamic, dynamic> {
  int parseToInt(String key) {
    if (!this.containsKey(key)) {
      return null;
    }
    if (this[key] is! int) {
      try {
        return int.parse(this[key] as String);
      } catch (er) {
        return null;
      }
    }
    return this[key];
  }
}
