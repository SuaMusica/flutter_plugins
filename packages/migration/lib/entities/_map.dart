extension MapParseInt on Map<dynamic, dynamic> {
  int parseToInt(String key) {
    if (this[key] == null) {
      return null;
    }

    return this[key] is String ? 
      int.parse(this[key] as String) : this[key] is int;
  }
}