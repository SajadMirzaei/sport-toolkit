import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/email_password_auth_service.dart';

class LoginProvider with ChangeNotifier {
  User? _user;
  AuthService? _authService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EmailPasswordAuthService _emailPasswordAuthService =
      EmailPasswordAuthService();

  LoginProvider() {
    debugPrint("LoginProvider - Constructor");
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
    for (var userInfo in userToSet!.providerData) {
      if (userInfo.providerId == 'password') {
        _authService = _emailPasswordAuthService;
        break;
      }
    }
  }

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  User? get user => _user;

  bool get isAdmin {
    return _user != null && _user!.email == 'mirzaei.sajad@gmail.com';
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    debugPrint("LoginProvider - loginWithEmailAndPassword");
    _authService ??= EmailPasswordAuthService();
    try {
      final user = await _authService!.signIn(email: email, password: password);
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
    //initialize authService if it's null
    _authService ??= EmailPasswordAuthService();
    try {
      final user = await _authService!.signUp(email: email, password: password);
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
    if (_authService != null) {
      return _authService!.getCurrentUser();
    }
    return _auth.currentUser; // Fallback to FirebaseAuth.instance
  }

  Future<void> logout() async {
    //logout the user
    debugPrint("LoginProvider - logout");
    if (_authService != null) {
      await _authService!.signOut();
    } else {
      await _auth.signOut(); // If authService is null for some reason
    }
    _authService = null;
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
