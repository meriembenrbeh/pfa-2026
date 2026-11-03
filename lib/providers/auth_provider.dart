import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserModel? _userModel;

  User? get user => _user;
  UserModel? get userModel => _userModel;

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _userModel = await _authService.getUser(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<String?> signUp(String email, String password, String name, String role) async {
    var (userCredential, error) = await _authService.signUp(email, password, name, role);
    if (userCredential != null) {
      _user = userCredential.user;
      _userModel = await _authService.getUser(userCredential.user!.uid);
      notifyListeners();
      return null;
    }
    return error;
  }

  Future<String?> signIn(String email, String password) async {
    var (userCredential, error) = await _authService.signIn(email, password);
    if (userCredential != null) {
      _user = userCredential.user;
      _userModel = await _authService.getUser(userCredential.user!.uid);
      notifyListeners();
      return null;
    }
    return error;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userModel = null;
    notifyListeners();
  }

  void setUser(UserModel userModel) {
    _userModel = userModel;
    notifyListeners();
  }
}
