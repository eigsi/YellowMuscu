// user_info.dart

class UserInfo {
  final double height;
  final double weight;
  final String email;
  final String password;
  final DateTime birthDate;

  UserInfo({
    required this.height,
    required this.weight,
    required this.email,
    required this.password,
    required this.birthDate,
  });

  // Méthode pour créer une copie de l'objet avec de nouvelles valeurs
  UserInfo copyWith({
    double? height,
    double? weight,
    String? email,
    String? password,
    DateTime? birthDate,
  }) {
    return UserInfo(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      email: email ?? this.email,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}
