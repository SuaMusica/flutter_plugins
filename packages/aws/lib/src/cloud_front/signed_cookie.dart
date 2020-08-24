abstract class SignedCookies {
  final DateTime expires;

  SignedCookies(this.expires);

  bool isValid() =>
      this.expires != null &&
      !(this.expires.difference(DateTime.now()).inMinutes <= 15);
}
