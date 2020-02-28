class User {
  User({
    this.id,
    this.name,
    this.cover,
    this.age,
    this.gender,
  });
  final String id;
  final String name;
  final String cover;
  final String gender;
  final int age;

  factory User.fromJson(Map<dynamic, dynamic> json) => User(
        id: json['userid'] as String,
        name: json['name'] as String,
        cover: json['cover'] as String,
        gender: json['gender'] as String,
        age: json['age'] as int,
      );

  Map<String, dynamic> toJson() => {
        'userid': this.id,
        'name': this.name,
        'cover': this.cover,
        'gender': this.gender,
        'age': this.age,
      };
}
