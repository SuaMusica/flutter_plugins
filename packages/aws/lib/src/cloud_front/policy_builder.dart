abstract class PolicyBuilder {
  String build(String resourceUrlOrPath, DateTime expiresOn,
      DateTime activeFrom, String ipRange);
}
