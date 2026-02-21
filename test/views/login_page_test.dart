import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/views/login_page.dart';
import 'package:provider/provider.dart';

import 'login_page_test.mocks.dart';

// Custom mock to simulate wrong password error
class MockFirebaseAuthForWrongPassword extends MockFirebaseAuth {
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (password == 'wrong-password') {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid for the given email.',
      );
    }
    return super.signInWithEmailAndPassword(email: email, password: password);
  }
}

// Custom mock to simulate email already in use error
class MockFirebaseAuthForEmailInUse extends MockFirebaseAuth {
  final List<String> existingEmails;

  MockFirebaseAuthForEmailInUse({this.existingEmails = const []});

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    if (existingEmails.contains(email)) {
      return Future.error(
        FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        ),
      );
    }
    return super.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}

@GenerateMocks([DataService])
void main() {
  late MockDataService mockDataService;
  late MockFirebaseAuth mockAuth;
  late LoginProvider loginProvider;

  setUp(() {
    mockDataService = MockDataService();
    mockAuth = MockFirebaseAuth();
    loginProvider = LoginProvider(mockAuth);
  });

  testWidgets('LoginPage should display title and subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginProvider>.value(value: loginProvider),
          ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text(kLoginPageTitle), findsOneWidget);
    expect(find.text(kLoginPageSubtitle), findsOneWidget);
  });

  testWidgets(
    'LoginPage should display email and password fields, and sign in/sign up buttons',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LoginProvider>.value(value: loginProvider),
            ChangeNotifierProvider<DataService>.value(value: mockDataService),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    },
  );

  testWidgets(
    'should sign up and create a user when sign up button is tapped',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LoginProvider>.value(value: loginProvider),
            ChangeNotifierProvider<DataService>.value(value: mockDataService),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'newuser@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.email, 'newuser@example.com');
    },
  );

  testWidgets('should log in a user when sign in button is tapped', (
    WidgetTester tester,
  ) async {
    // Create a user to log in with.
    await mockAuth.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    );
    mockAuth.signOut();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginProvider>.value(value: loginProvider),
          ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(mockAuth.currentUser, isNotNull);
    expect(mockAuth.currentUser!.email, 'test@example.com');
  });

  testWidgets('should show error when email is invalid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginProvider>.value(value: loginProvider),
          ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'invalid-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

  testWidgets('should show error when email or password is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginProvider>.value(value: loginProvider),
          ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('should show error when password is less than 6 characters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginProvider>.value(value: loginProvider),
          ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      '12345',
    );
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('should show a SnackBar and not log in when password is wrong', (
    WidgetTester tester,
  ) async {
    // Use the custom mock that throws a specific error
    final mockAuthWithWrongPassword = MockFirebaseAuthForWrongPassword();
    // Create a user first, so the login can be attempted.
    await mockAuthWithWrongPassword.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    );
    await mockAuthWithWrongPassword.signOut();

    // Create a new provider with the custom mock
    final loginProviderWithWrongPassword = LoginProvider(
      mockAuthWithWrongPassword,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginProvider>.value(
            value: loginProviderWithWrongPassword,
          ),
          ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ],
        // The Scaffold is necessary for the SnackBar to be displayed.
        child: const MaterialApp(home: Scaffold(body: LoginPage())),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong-password',
    );
    await tester.tap(find.text('Sign In'));

    // Pump a single frame to allow the SnackBar to appear.
    await tester.pump();

    // Check that a SnackBar is displayed, without checking the specific message.
    expect(find.byType(SnackBar), findsOneWidget);
    // Also check that the login was not successful.
    expect(loginProviderWithWrongPassword.user, isNull);
  });

  testWidgets(
    'should show a SnackBar when signing up with an email that is already in use',
    (WidgetTester tester) async {
      // Setup the mock to know about the existing email.
      final mockAuthWithExistingEmail = MockFirebaseAuthForEmailInUse(
        existingEmails: ['test@example.com'],
      );

      // Create a provider with this specific mock.
      final loginProviderForTest = LoginProvider(mockAuthWithExistingEmail);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LoginProvider>.value(
              value: loginProviderForTest,
            ),
            ChangeNotifierProvider<DataService>.value(value: mockDataService),
          ],
          // The Scaffold is necessary for the SnackBar to be displayed.
          child: const MaterialApp(home: Scaffold(body: LoginPage())),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'new-password',
      );
      await tester.tap(find.text('Sign Up'));

      // Pump a single frame to allow the SnackBar to appear.
      await tester.pump();

      // Check that a SnackBar is displayed.
      expect(find.byType(SnackBar), findsOneWidget);
      // Check that the sign up was not successful.
      expect(loginProviderForTest.user, isNull);
    },
  );
}
