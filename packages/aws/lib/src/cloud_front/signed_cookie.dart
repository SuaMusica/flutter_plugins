abstract class SignedCookies {
  final DateTime expires;
  final int difference;

  SignedCookies(this.difference, this.expires);

  int get expiresIn => this.expires == null
      ? 0
      : this
          .expires
          .difference(DateTime.now().add(Duration(milliseconds: difference)))
          .inMinutes;
  bool get isValid => this.expiresIn > 15;
}
