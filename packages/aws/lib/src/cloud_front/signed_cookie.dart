class SignedCookies {
  final DateTime expires;

  SignedCookies(this.expires);

  bool isValid() {
    return this.expires != null &&
        !this.expires.difference(DateTime.now()).isNegative;
  }
}