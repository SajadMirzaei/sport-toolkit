import 'package:firebase_auth/firebase_auth.dart';

class EmailPasswordAuthService {
  final FirebaseAuth _auth;

  EmailPasswordAuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}