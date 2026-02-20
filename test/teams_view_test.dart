import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/views/teams_view.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'teams_view_test.mocks.dart';

// Generate mocks for the services
@GenerateMocks([DataService, AuthService, User, LoginProvider])
void main() {
  late MockDataService mockDataService;
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late MockLoginProvider mockLoginProvider;

  // Helper to create the widget tree with providers.
  Widget createTeamsPage() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>.value(value: mockDataService),
        Provider<AuthService>.value(value: mockAuthService),
        ChangeNotifierProvider<LoginProvider>.value(value: mockLoginProvider),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TeamsPage()),
      ),
    );
  }

  setUp(() {
    mockDataService = MockDataService();
    mockAuthService = MockAuthService();
    mockUser = MockUser();
    mockLoginProvider = MockLoginProvider();

    // Stubs for DataService
    when(mockDataService.latestRoster).thenReturn(
      WeeklyRoster(id: 'roster1', date: '01/01/2024', playerIds: [], playerNames: [], numberOfTeams: 2)
    );
    when(mockDataService.fetchLatestRoster()).thenAnswer((_) async {});
    when(mockDataService.isLoadingRoster).thenReturn(false);
    when(mockDataService.players).thenReturn([]);
    when(mockDataService.suggestedTeams).thenReturn([]);
    when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);

    // Stubs for AuthService
    when(mockAuthService.getCurrentUser()).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('uid-123');

    // Stubs for LoginProvider
    when(mockLoginProvider.user).thenReturn(mockUser);
  });

  group('TeamsPage', () {
    testWidgets('renders TabBar and initial TeamFormationPage', (WidgetTester tester) async {
      await tester.pumpWidget(createTeamsPage());
      await tester.pumpAndSettle();

      // Verify that the TabBar and tabs are present
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Suggest Teams'), findsOneWidget);
      expect(find.text('Vote Teams'), findsOneWidget);

      // Verify that the TeamFormationPage is initially displayed
      expect(find.text('Unassigned Players'), findsOneWidget);
      expect(find.text('Team 1'), findsOneWidget);
    });

    testWidgets('tapping "Vote Teams" tab shows TeamVotingView', (WidgetTester tester) async {
      await tester.pumpWidget(createTeamsPage());
      await tester.pumpAndSettle();

      // Tap the 'Vote Teams' tab
      await tester.tap(find.text('Vote Teams'));
      await tester.pumpAndSettle();

      // Verify that the TeamVotingView is displayed
      expect(find.text('No suggested teams available for the latest roster.'), findsOneWidget);
    });

    testWidgets('tapping "Suggest Teams" tab shows TeamFormationPage again', (WidgetTester tester) async {
      await tester.pumpWidget(createTeamsPage());
      await tester.pumpAndSettle();

      // Go to Voting tab first
      await tester.tap(find.text('Vote Teams'));
      await tester.pumpAndSettle();

      // Tap the 'Suggest Teams' tab to go back
      await tester.tap(find.text('Suggest Teams'));
      await tester.pumpAndSettle();

      // Verify that the TeamFormationPage is displayed again
      expect(find.text('Unassigned Players'), findsOneWidget);
    });
  });
}
