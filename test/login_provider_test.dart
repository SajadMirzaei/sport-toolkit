import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:mockito/mockito.dart';

// Mock listener to verify notifyListeners was called
class MockListener extends Mock {
  void call();
}

// Mock for testing signIn failures by throwing an exception.
class MockAuthForSignInFailure extends MockFirebaseAuth {
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(code: 'user-not-found');
  }
}

// Mock for testing signUp failures by throwing an exception.
class MockAuthForSignUpFailure extends MockFirebaseAuth {
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(code: 'email-already-in-use');
  }
}

void main() {
  final adminEmail = 'mirzaei.sajad@gmail.com';
  final regularUserEmail = 'test@example.com';

  group('LoginProvider Tests', () {
    group('isAdmin Getter', () {
      test('returns true for the admin email', () {
        final provider = LoginProvider(MockFirebaseAuth());
        provider.setUser(MockUser(email: adminEmail));
        expect(provider.isAdmin, isTrue);
      });

      test('returns false for a non-admin email', () {
        final provider = LoginProvider(MockFirebaseAuth());
        provider.setUser(MockUser(email: regularUserEmail));
        expect(provider.isAdmin, isFalse);
      });

      test('returns false when no user is logged in', () {
        final provider = LoginProvider(MockFirebaseAuth());
        expect(provider.isAdmin, isFalse);
      });
    });

    group('User State', () {
      test('constructor sets display name from email if user has no display name', () async {
        final user = MockUser(email: 'newbie@example.com', displayName: null);
        final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
        
        final completer = Completer<void>();
        final provider = LoginProvider(auth);

        provider.addListener(() {
          if (provider.user?.displayName == 'newbie' && !completer.isCompleted) {
            completer.complete();
          }
        });

        await completer.future.timeout(const Duration(seconds: 2));
        expect(provider.user?.displayName, 'newbie');
      });

      test('logout clears the user and notifies listeners', () async {
        final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser());
        final provider = LoginProvider(auth);
        
        await Future.microtask(() {}); // allow _initUser to run
        expect(provider.user, isNotNull, reason: "User should be initialized");

        final listener = MockListener();
        provider.addListener(listener);

        await provider.logout();

        expect(provider.user, isNull, reason: "User should be null after logout");
        verify(listener.call()).called(1);
      });
    });

    group('Authentication Flows', () {
       test('signUp successfully signs up and initializes the user', () async {
        final auth = MockFirebaseAuth();
        final provider = LoginProvider(auth);

        await provider.signUp('newbie@example.com', 'password123');
        
        expect(provider.user, isNotNull);
        expect(provider.user?.email, 'newbie@example.com');
      });

      test('loginWithEmailAndPassword sets display name if user has empty display name', () async {
        final auth = MockFirebaseAuth();
        // Create a user, which by default has a display name.
        final creationResult = await auth.createUserWithEmailAndPassword(email: 'surfer@example.com', password: 'password');
        // Manually update the user to have an empty display name for our test case.
        await creationResult.user!.updateDisplayName('');
        // Sign out to ensure we test the login flow, not just an already-logged-in state.
        await auth.signOut();

        final provider = LoginProvider(auth);

        final completer = Completer<void>();
        provider.addListener(() {
          // We expect the provider to update the display name to 'surfer'.
          if (provider.user?.displayName == 'surfer' && !completer.isCompleted) {
            completer.complete();
          }
        });

        await provider.loginWithEmailAndPassword('surfer@example.com', 'password');
        // Wait for the async listener to be called.
        await completer.future.timeout(const Duration(seconds: 2));
        
        expect(provider.user?.displayName, 'surfer');
      });


      test('loginWithEmailAndPassword re-throws exceptions on failure', () {
        final provider = LoginProvider(MockAuthForSignInFailure());
        expect(
          provider.loginWithEmailAndPassword('a@b.com', 'password'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signUp re-throws exceptions on failure', () {
        final provider = LoginProvider(MockAuthForSignUpFailure());
        expect(
          provider.signUp('a@b.com', 'password'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });
  });
}
