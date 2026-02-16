import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/views/login_page.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';

import 'login_page_test.mocks.dart';

// Test values
const String kAppId = '1:1234567890:web:12345';
const String kWebApiKey = '123';
const String kProjectId = 'test-project';
const String kMessagingSenderId = '1234567890';
const String kAuthDomain = 'test-project.firebaseapp.com';

// A mock implementation of FirebaseAppPlatform.
class MockFirebaseAppPlatform extends Fake with MockPlatformInterfaceMixin implements FirebaseAppPlatform {
  MockFirebaseAppPlatform(String name, FirebaseOptions options) : super();

  @override
  String get name => '[DEFAULT]';

  @override
  FirebaseOptions get options => const FirebaseOptions(
        appId: kAppId,
        apiKey: kWebApiKey,
        projectId: kProjectId,
        messagingSenderId: kMessagingSenderId,
        authDomain: kAuthDomain,
      );
}

// A mock implementation of FirebasePlatform.
class MockFirebasePlatform extends Fake with MockPlatformInterfaceMixin implements FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseAppPlatform(name ?? '[DEFAULT]', options ?? const FirebaseOptions(
        appId: kAppId,
        apiKey: kWebApiKey,
        projectId: kProjectId,
        messagingSenderId: kMessagingSenderId,
        authDomain: kAuthDomain,
      ),);
  }

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return MockFirebaseAppPlatform(name, const FirebaseOptions(
        appId: kAppId,
        apiKey: kWebApiKey,
        projectId: kProjectId,
        messagingSenderId: kMessagingSenderId,
        authDomain: kAuthDomain,
      ),);
  }
  
  @override
  List<FirebaseAppPlatform> get apps => [app()];
}

@GenerateMocks([LoginProvider, DataService])
void main() {
  late MockLoginProvider mockLoginProvider;
  late MockDataService mockDataService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FirebasePlatform.instance = MockFirebasePlatform();

    await Firebase.initializeApp();

    mockLoginProvider = MockLoginProvider();
    mockDataService = MockDataService();
  });

  testWidgets(
      'LoginPage should display email and password fields, and sign in/sign up buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginProvider>.value(value: mockLoginProvider),
          ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
  });
}
