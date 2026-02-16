import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';

const List<String> scopes = <String>['email'];

class GoogleAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: scopes);

  GoogleSignInAccount? _currentUser;

  GoogleAuthService() {
    _googleSignIn.onCurrentUserChanged.listen((
      GoogleSignInAccount? account,
    ) async {
      _currentUser = account;
      signIn();
    });
  }

  @override
  Future<User> signIn({String? email, String? password}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      _currentUser = googleUser;
      if (googleUser == null) {
        throw Exception("Google sign in was canceled.");
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user!;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _currentUser = null;
  }

  @override
  Future<User> signUp({String? email, String? password}) {
    throw UnimplementedError();
  }

  @override
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
