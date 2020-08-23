class ScannedMedia {

  ScannedMedia(this.title);

  String title;

  @override
  String toString() {
    return 'MediaScanned{title: $title}';
  }

  static ScannedMedia fromMap(Map<dynamic, dynamic> map) {
    return ScannedMedia(
      map["title"] as String
    );
  }
}