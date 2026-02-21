
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/services/email_password_auth_service.dart';

import 'email_password_auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, UserCredential, User])
void main() {
  late EmailPasswordAuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    authService = EmailPasswordAuthService(mockAuth);
  });

  group('EmailPasswordAuthService', () {
    const email = 'test@example.com';
    const password = 'password123';

    // signIn tests
    group('signIn', () {
      test('should return User on successful sign in', () async {
        when(mockAuth.signInWithEmailAndPassword(email: email, password: password))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);

        final result = await authService.signIn(email: email, password: password);

        expect(result, mockUser);
      });

      test('should throw an exception if email or password is null', () {
        expect(() => authService.signIn(email: null, password: password),
            throwsA(isA<Exception>()));
        expect(() => authService.signIn(email: email, password: null),
            throwsA(isA<Exception>()));
      });

      test('should rethrow FirebaseAuthException on failure', () {
        final exception = FirebaseAuthException(code: 'user-not-found');
        when(mockAuth.signInWithEmailAndPassword(email: email, password: password))
            .thenThrow(exception);

        expect(() => authService.signIn(email: email, password: password),
            throwsA(isA<FirebaseAuthException>()));
      });
    });

    // signUp tests
    group('signUp', () {
      test('should return User on successful sign up', () async {
        when(mockAuth.createUserWithEmailAndPassword(email: email, password: password))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);

        final result = await authService.signUp(email: email, password: password);

        expect(result, mockUser);
      });

      test('should throw an exception if email or password is null', () {
        expect(() => authService.signUp(email: null, password: password),
            throwsA(isA<Exception>()));
        expect(() => authService.signUp(email: email, password: null),
            throwsA(isA<Exception>()));
      });

      test('should rethrow FirebaseAuthException on failure', () {
        final exception = FirebaseAuthException(code: 'email-already-in-use');
        when(mockAuth.createUserWithEmailAndPassword(email: email, password: password))
            .thenThrow(exception);

        expect(() => authService.signUp(email: email, password: password),
            throwsA(isA<FirebaseAuthException>()));
      });
    });

    // signOut test
    group('signOut', () {
      test('should call signOut on FirebaseAuth instance', () async {
        when(mockAuth.signOut()).thenAnswer((_) async => {});
        await authService.signOut();
        verify(mockAuth.signOut()).called(1);
      });
    });

    // getCurrentUser test
    group('getCurrentUser', () {
      test('should return the current user from FirebaseAuth', () {
        when(mockAuth.currentUser).thenReturn(mockUser);

        final result = authService.getCurrentUser();

        expect(result, mockUser);
      });

      test('should return null if no user is signed in', () {
        when(mockAuth.currentUser).thenReturn(null);

        final result = authService.getCurrentUser();

        expect(result, isNull);
      });
    });
  });
}
