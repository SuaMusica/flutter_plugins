import 'package:flutter/material.dart';
import 'package:smads/adevent_type.dart';

class AdEvent {
  AdEvent(
      {
        @required this.type, 
        @required this.id,
        @required this.title,
        @required this.description,
        @required this.system,
        @required this.advertiserName,
        @required this.contentType,
        @required this.creativeAdID,
        @required this.creativeID,
        @required this.dealID,
      });

  final AdEventType type;
  final String id;
  final String title;
  final String description;
  final String system;
  final String advertiserName;
  final String contentType;
  final String creativeAdID;
  final String creativeID;
  final String dealID;

  @override
  String toString() =>
      "AdEvent type: $type id: $id description: $description " +
      "system: $system advertiserName: $advertiserName contentType: $contentType " +
      "creativeAdID: $creativeAdID creativeID: $creativeID dealID: $dealID";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          system == other.system &&
          advertiserName == other.advertiserName &&
          contentType == other.contentType &&
          creativeAdID == other.creativeAdID &&
          creativeID == other.creativeID &&
          dealID == other.dealID;

  @override
  int get hashCode => [type].hashCode;

  factory AdEvent.fromMap(Map<dynamic, dynamic> args) {
    final type = AdEventType.values.firstWhere((e) => e.toString() == "AdEventType.${args["type"]}");
    final id = args["ad.id"];
    final title = args["ad.title"];
    final description = args["ad.description"];
    final system = args["ad.system"];
    final advertiserName = args["ad.advertiserName"];
    final contentType = args["ad.contentType"];
    final creativeAdID = args["ad.creativeAdID"];
    final creativeID = args["ad.creativeID"];
    final dealID = args["ad.dealID"];
    return AdEvent(
      type: type,
      id: id,
      title: title,
      description: description,
      system: system,
      advertiserName: advertiserName, 
      contentType: contentType,
      creativeAdID: creativeAdID,
      creativeID: creativeID,
      dealID: dealID,
    );
  }
}
