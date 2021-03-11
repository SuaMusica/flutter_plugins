abstract class SignedCookies {
  final DateTime expires;
  final int? difference;

  SignedCookies(this.difference, this.expires);

  int get expiresIn => this
      .expires
      .difference(DateTime.now().add(Duration(milliseconds: difference ?? 0)))
      .inMinutes;
  bool get isValid => this.expiresIn > 15;
}
