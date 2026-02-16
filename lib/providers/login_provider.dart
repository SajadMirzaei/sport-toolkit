import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/auth_service.dart';
import 'package:myapp/email_password_auth_service.dart';
import 'package:myapp/google_auth_service.dart';

class LoginProvider with ChangeNotifier {
  User? _user;
  AuthService? _authService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final EmailPasswordAuthService _emailPasswordAuthService =
      EmailPasswordAuthService();

  LoginProvider() {
    debugPrint("LoginProvider - Constructor");
    final user = _auth.currentUser;
    debugPrint("LoginProvider - Constructor: user: ${user?.email ?? 'null'}");
    if (user != null) {
      setUser(user);
      for (var userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          _authService = _googleAuthService;
          break;
        } else if (userInfo.providerId == 'password') {
          _authService = _emailPasswordAuthService;
          break;
        }
      }
    }
  }

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  User? get user => _user;

  Future<void> googleLogin() async {
    debugPrint("LoginProvider - login google");
    _authService ??= GoogleAuthService();
    try {
      final user =
          await _authService!.signIn();
      setUser(user);
    } catch (e) {
      debugPrint("LoginProvider - login - Error: $e");
      rethrow;
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    debugPrint("LoginProvider - loginWithEmailAndPassword");
    _authService ??= EmailPasswordAuthService();
    try {
      final user = await _authService!.signIn(email: email, password: password);
      setUser(user); // we pass the parameters for email/password
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
      setUser(user);
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
    return null;
  }

  Future<void> logout() async {
    //logout the user
    debugPrint("LoginProvider - logout");
    if (_authService != null) {
      await _authService!.signOut();
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
