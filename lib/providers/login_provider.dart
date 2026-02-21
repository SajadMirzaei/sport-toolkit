import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/email_password_auth_service.dart';

class LoginProvider with ChangeNotifier {
  User? _user;
  late final EmailPasswordAuthService _authService;
  final FirebaseAuth _auth;

  LoginProvider(this._auth) {
    debugPrint("LoginProvider - Constructor");
    _authService = EmailPasswordAuthService(_auth);
    final user = _auth.currentUser;
    debugPrint("LoginProvider - Constructor: user: ${user?.email ?? 'null'}");
    if (user != null) {
      _initUser(user);
    }
  }

  Future<void> _initUser(User user) async {
    User? userToSet = user;
    if (user.displayName == null || user.displayName!.isEmpty) {
      if (user.email != null) {
        final displayName = user.email!.split('@').first;
        try {
          await user.updateDisplayName(displayName);
          await user.reload();
          userToSet = _auth.currentUser;
        } catch (e) {
          debugPrint("Failed to update display name: $e");
        }
      }
    }
    setUser(userToSet);
  }

  User? get user => _user;

  bool get isAdmin {
    return _user != null && _user!.email == 'mirzaei.sajad@gmail.com';
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    debugPrint("LoginProvider - loginWithEmailAndPassword");
    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user != null) {
        await _initUser(user);
      }
    } catch (e) {
      debugPrint("LoginProvider - login - Error: $e");
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    //signup with email and password
    debugPrint("LoginProvider - signup");
    try {
      final user = await _authService.signUp(email: email, password: password);
      if (user != null) {
        await _initUser(user);
      }
    } catch (e) {
      debugPrint("LoginProvider - login - Error: $e");
      rethrow;
    }
  }

  User? getCurrentUser() {
    //get the current user logged in
    debugPrint("LoginProvider - getCurrentUser");
    return _authService.getCurrentUser();
  }

  Future<void> logout() async {
    //logout the user
    debugPrint("LoginProvider - logout");
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void setUser(User? newUser) {
    debugPrint(
      "LoginProvider - setUser: ${newUser?.displayName}, ${newUser?.email}",
    );
    if (newUser != null) {
      _user = newUser;
      notifyListeners();
    }
  }
}