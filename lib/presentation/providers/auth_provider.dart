import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? user;
  bool isLoading = false;
  String userRole = 'user';
  Map<String, dynamic>? currentUserModel;

  bool get isLoggedIn => user != null;
  bool get isAdmin => userRole == 'admin';

  Future<void> loadCurrentUser() async {}

  void setVisitorProfile({required String name, required String municipality}) {
    user = 'demo-user';
    userRole = 'user';
    currentUserModel = {'uid': user, 'name': name, 'city': municipality};
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) return false;
    user = 'demo-user';
    currentUserModel = {
      'uid': user,
      'email': email.trim(),
      'name': 'Visitante',
    };
    userRole = 'user';
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String city,
    required String phone,
  }) async {
    user = 'demo-user';
    currentUserModel = {
      'uid': user,
      'name': name,
      'email': email,
      'city': city,
      'phone': phone,
    };
    userRole = 'user';
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    user = null;
    userRole = 'user';
    currentUserModel = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    throw UnsupportedError(
      'La recuperación de contraseña no está disponible en el modo local.',
    );
  }
}
