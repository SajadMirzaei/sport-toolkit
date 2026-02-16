import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Future<User> signIn({String? email, String? password});
  Future<User> signUp({String? email, String? password});
  Future<void> signOut();
  User? getCurrentUser();
}
