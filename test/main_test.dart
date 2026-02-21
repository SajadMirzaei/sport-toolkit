import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/main.dart';
import 'package:myapp/views/login_page.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:myapp/services/data_service.dart';

import 'main_test.mocks.dart';

// Mock Firebase
Future<FirebaseApp> mockFirebase() async {
  final app = MockFirebaseApp();
  return app;
}

@GenerateMocks([FirebaseApp, FirebaseAuth, User, LoginProvider, DataService])
void main() {
  // Use a mock version of Firebase
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLoginProvider mockLoginProvider;
  late MockDataService mockDataService;
  late MockUser mockUser;

  setUp(() {
    mockLoginProvider = MockLoginProvider();
    mockDataService = MockDataService();
    mockUser = MockUser();

    // Default stubs for LoginProvider
    when(mockLoginProvider.getCurrentUser()).thenReturn(null);
    when(mockLoginProvider.logout()).thenAnswer((_) async {});
    when(mockLoginProvider.user).thenReturn(null);
    when(mockLoginProvider.isAdmin).thenReturn(false);

    // Default stubs for DataService
    when(mockDataService.fetchPlayers()).thenAnswer((_) async {});
    when(mockDataService.fetchLatestRoster()).thenAnswer((_) async {});
    when(mockDataService.fetchSuggestedTeams()).thenAnswer((_) async {});
    when(mockDataService.players).thenReturn([]);
    when(mockDataService.latestRoster).thenReturn(null);
    when(mockDataService.suggestedTeams).thenReturn([]);
    when(mockDataService.isLoadingPlayers).thenReturn(false);
    when(mockDataService.isLoadingRoster).thenReturn(false);
    when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginProvider>.value(value: mockLoginProvider),
        ChangeNotifierProvider<DataService>.value(value: mockDataService),
      ],
      child: MaterialApp(
        home: child,
        routes: {'/login': (context) => const LoginPage()},
      ),
    );
  }

  group('MyApp', () {
    testWidgets(
      'shows CircularProgressIndicator while Firebase is initializing',
      (tester) async {
        await tester.pumpWidget(const MyApp());
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });

  group('LoginChecker', () {
    testWidgets('shows HomePage when user is logged in', (tester) async {
      when(mockLoginProvider.getCurrentUser()).thenReturn(mockUser);
      when(mockLoginProvider.user).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget(const LoginChecker()));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('shows LoginPage when user is not logged in', (tester) async {
      when(mockLoginProvider.getCurrentUser()).thenReturn(null);

      await tester.pumpWidget(createTestWidget(const LoginChecker()));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
    });
  });

  group('HomePage', () {
    testWidgets('shows admin tabs for admin user', (tester) async {
      when(mockLoginProvider.user).thenReturn(mockUser);
      when(mockLoginProvider.isAdmin).thenReturn(true);

      await tester.pumpWidget(createTestWidget(const HomePage()));

      expect(find.text('Ratings'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Players'), findsOneWidget);
    });

    testWidgets('shows regular tabs for non-admin user', (tester) async {
      when(mockLoginProvider.user).thenReturn(mockUser);
      when(mockLoginProvider.isAdmin).thenReturn(false);

      await tester.pumpWidget(createTestWidget(const HomePage()));

      expect(find.text('Ratings'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Players'), findsNothing);
    });

    testWidgets('logout button logs out and navigates to login', (
      tester,
    ) async {
      when(mockLoginProvider.user).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget(const HomePage()));

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      verify(mockLoginProvider.logout()).called(1);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('login button navigates to login when logged out', (
      tester,
    ) async {
      when(mockLoginProvider.user).thenReturn(null);

      await tester.pumpWidget(createTestWidget(const HomePage()));

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
