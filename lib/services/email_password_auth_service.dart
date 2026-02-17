import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class EmailPasswordAuthService implements AuthService {
  final FirebaseAuth _auth;

  EmailPasswordAuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

   @override
  Future<User> signIn({String? email, String? password}) async {
    if (email == null || password == null) {
      throw Exception('Email and password are required');
    }
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!;
    } catch (e) {
      rethrow;
    }
  }

 @override
  Future<User> signUp({String? email, String? password}) async {
    if (email == null || password == null) {
      throw Exception('Email and password are required');
    }
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!;
       } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}