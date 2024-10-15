// user_info_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/data/user_info.dart';

// StateNotifier qui gère l'état de UserInfo
class UserInfoNotifier extends StateNotifier<UserInfo> {
  UserInfoNotifier()
      : super(UserInfo(
          height: 180.0,
          weight: 70.0,
          email: 'example@mail.com',
          password: 'password123',
          birthDate: DateTime(1990, 1, 1),
        ));

  void updateHeight(double newHeight) {
    state = state.copyWith(height: newHeight);
  }

  void updateWeight(double newWeight) {
    state = state.copyWith(weight: newWeight);
  }

  void updateEmail(String newEmail) {
    state = state.copyWith(email: newEmail);
  }

  void updatePassword(String newPassword) {
    state = state.copyWith(password: newPassword);
  }

  void updateBirthDate(DateTime newBirthDate) {
    state = state.copyWith(birthDate: newBirthDate);
  }
}

// StateNotifierProvider qui expose UserInfoNotifier
final userInfoProvider = StateNotifierProvider<UserInfoNotifier, UserInfo>(
  (ref) => UserInfoNotifier(),
);
