import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:myapp/services/email_password_auth_service.dart';

import 'login_provider_test.mocks.dart';

// Mock listener to verify notifyListeners was called
class MockListener extends Mock {
  void call();
}

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
  MockSpec<UserCredential>(),
  MockSpec<EmailPasswordAuthService>(),
])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  final adminEmail = 'mirzaei.sajad@gmail.com';
  final regularUserEmail = 'test@example.com';

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
  });

  group('LoginProvider Tests', () {
    group('isAdmin Getter', () {
      test('returns true for the admin email', () {
        when(mockAuth.currentUser).thenReturn(null);
        final provider = LoginProvider(mockAuth);
        when(mockUser.email).thenReturn(adminEmail);
        provider.setUser(mockUser);
        expect(provider.isAdmin, isTrue);
      });

      test('returns false for a non-admin email', () {
        when(mockAuth.currentUser).thenReturn(null);
        final provider = LoginProvider(mockAuth);
        when(mockUser.email).thenReturn(regularUserEmail);
        provider.setUser(mockUser);
        expect(provider.isAdmin, isFalse);
      });

      test('returns false when no user is logged in', () {
        when(mockAuth.currentUser).thenReturn(null);
        final provider = LoginProvider(mockAuth);
        expect(provider.isAdmin, isFalse);
      });
    });

    group('User State', () {
      test(
        'constructor sets display name from email if user has no display name',
        () async {
          when(mockUser.email).thenReturn('newbie@example.com');
          when(mockUser.displayName).thenReturn(null);
          when(mockAuth.currentUser).thenReturn(mockUser);

          LoginProvider(mockAuth);

          await Future.delayed(Duration.zero); // allow _initUser to complete

          verify(mockUser.updateDisplayName('newbie')).called(1);
        },
      );

      test('logout clears the user and notifies listeners', () async {
        when(mockUser.email).thenReturn(regularUserEmail);
        when(mockUser.displayName).thenReturn('regular');
        when(mockAuth.currentUser).thenReturn(mockUser);
        final provider = LoginProvider(mockAuth);

        await Future.delayed(Duration.zero); // allow _initUser to run
        expect(provider.user, isNotNull, reason: "User should be initialized");

        final listener = MockListener();
        provider.addListener(listener.call);

        await provider.logout();

        expect(
          provider.user,
          isNull,
          reason: "User should be null after logout",
        );
        verify(listener.call()).called(1);
      });
    });

    group('Authentication Flows', () {
      test('signUp successfully signs up and initializes the user', () async {
        when(mockAuth.currentUser).thenReturn(null); // No user initially
        final provider = LoginProvider(mockAuth);

        when(
          mockAuth.createUserWithEmailAndPassword(
            email: 'newbie@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.email).thenReturn('newbie@example.com');
        when(mockUser.displayName).thenReturn('Mock User');

        await provider.signUp('newbie@example.com', 'password123');

        expect(provider.user, isNotNull);
        expect(provider.user?.email, 'newbie@example.com');
      });

      test(
        'loginWithEmailAndPassword sets display name if user has empty display name',
        () async {
          when(mockAuth.currentUser).thenReturn(null); // Start logged out
          final provider = LoginProvider(mockAuth);

          when(
            mockAuth.signInWithEmailAndPassword(
              email: 'surfer@example.com',
              password: 'password',
            ),
          ).thenAnswer((_) async => mockUserCredential);
          when(mockUserCredential.user).thenReturn(mockUser);
          when(mockUser.displayName).thenReturn('');
          when(mockUser.email).thenReturn('surfer@example.com');
          when(mockAuth.currentUser).thenReturn(mockUser);

          await provider.loginWithEmailAndPassword(
            'surfer@example.com',
            'password',
          );

          await Future.delayed(Duration.zero);

          verify(mockUser.updateDisplayName('surfer')).called(1);
        },
      );

      test('loginWithEmailAndPassword re-throws exceptions on failure', () {
        when(
          mockAuth.signInWithEmailAndPassword(
            email: 'a@b.com',
            password: 'password',
          ),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found'));
        final provider = LoginProvider(mockAuth);
        expect(
          provider.loginWithEmailAndPassword('a@b.com', 'password'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signUp re-throws exceptions on failure', () {
        when(
          mockAuth.createUserWithEmailAndPassword(
            email: 'a@b.com',
            password: 'password',
          ),
        ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
        final provider = LoginProvider(mockAuth);
        expect(
          provider.signUp('a@b.com', 'password'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('getCurrentUser returns the current user from auth service', () {
        // Arrange
        final provider = LoginProvider(mockAuth);
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final user = provider.getCurrentUser();

        // Assert
        expect(user, mockUser);
      });
    });
  });
}
