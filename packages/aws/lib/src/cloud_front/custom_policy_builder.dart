import 'package:smaws/src/cloud_front/policy_builder.dart';

class CustomPolicyBuilder implements PolicyBuilder {
  String build(String resourceUrlOrPath, DateTime expiresOn,
      DateTime? activeFrom, String? ipRange) {
    ArgumentError.checkNotNull(resourceUrlOrPath);
    ArgumentError.checkNotNull(expiresOn);

    String policy = "{\"Statement\":[{" +
        "\"Resource\":\"" +
        resourceUrlOrPath +
        "\"" +
        ",\"Condition\":{" +
        "\"DateLessThan\":{\"AWS:EpochTime\":" +
        Duration(milliseconds: expiresOn.millisecondsSinceEpoch)
            .inSeconds
            .toString() +
        "}" +
        (ipRange == null
            ? ""
            : ",\"IpAddress\":{\"AWS:SourceIp\":\"" + ipRange + "\"}") +
        (activeFrom == null
            ? ""
            : ",\"DateGreaterThan\":{\"AWS:EpochTime\":" +
                Duration(milliseconds: activeFrom.millisecondsSinceEpoch)
                    .inSeconds
                    .toString() +
                "}") +
        "}}]}";
    return policy.split(" ").join("");
  }
}
