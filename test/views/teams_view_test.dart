import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/views/teams_view.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'teams_view_test.mocks.dart';

// Generate mocks for the services
@GenerateMocks([DataService, User, LoginProvider])
void main() {
  late MockDataService mockDataService;
  late MockUser mockUser;
  late MockLoginProvider mockLoginProvider;

  final List<Player> mockPlayers = [
    Player(id: 'p1', name: 'Player 1'),
    Player(id: 'p2', name: 'Player 2'),
  ];

  final mockRoster = WeeklyRoster(
    id: 'roster1',
    date: '01/01/2024',
    playerIds: const ['p1', 'p2'],
    playerNames: const ['Player 1', 'Player 2'],
    numberOfTeams: 2,
  );

  // Helper to create the widget tree with providers.
  Widget createTeamsPage() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ChangeNotifierProvider<LoginProvider>.value(value: mockLoginProvider),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TeamsPage()),
      ),
    );
  }

  setUp(() {
    mockDataService = MockDataService();
    mockUser = MockUser();
    mockLoginProvider = MockLoginProvider();

    // Stubs for DataService
    when(mockDataService.latestRoster).thenReturn(mockRoster);
    when(mockDataService.fetchLatestRoster()).thenAnswer((_) async {});
    when(mockDataService.isLoadingRoster).thenReturn(false);
    when(mockDataService.players).thenReturn(mockPlayers);
    when(mockDataService.fetchPlayers()).thenAnswer((_) async {});
    when(mockDataService.suggestedTeams).thenReturn([]);
    when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);

    // Stubs for LoginProvider
    when(mockLoginProvider.user).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('uid-123');
  });

  group('TeamsPage', () {
    testWidgets('renders TabBar and initial TeamFormationPage', (WidgetTester tester) async {
      // Use an empty roster for this test to keep it simple
      when(mockDataService.latestRoster).thenReturn(
        WeeklyRoster(id: 'roster1', date: '01/01/2024', playerIds: [], playerNames: [], numberOfTeams: 2)
      );
      when(mockDataService.players).thenReturn([]);

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

    testWidgets('TeamFormationPage state is preserved when switching tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTeamsPage());
      await tester.pumpAndSettle();

      // 1. Find a player and drag them to Team 1
      final playerChip = find.widgetWithText(Chip, 'Player 1');
      final teamTarget = find.ancestor(
        of: find.text('Team 1'), 
        matching: find.byType(Card)
      );
      expect(playerChip, findsOneWidget);
      expect(teamTarget, findsOneWidget);

      final Offset playerChipCenter = tester.getCenter(playerChip);
      final Offset teamTargetCenter = tester.getCenter(teamTarget);
      final Offset dragOffset = teamTargetCenter - playerChipCenter;

      await tester.drag(playerChip, dragOffset);
      await tester.pumpAndSettle();

      // 2. Verify the player is in Team 1
      final playerInTeam = find.descendant(
        of: teamTarget, 
        matching: find.widgetWithText(Chip, 'Player 1')
      );
      expect(playerInTeam, findsOneWidget);

      // 3. Switch to the 'Vote Teams' tab
      await tester.tap(find.text('Vote Teams'));
      await tester.pumpAndSettle();

      // 4. Switch back to the 'Suggest Teams' tab
      await tester.tap(find.text('Suggest Teams'));
      await tester.pumpAndSettle();

      // 5. Verify the player is still in Team 1
      final teamTargetAfterSwitch = find.ancestor(
        of: find.text('Team 1'), 
        matching: find.byType(Card)
      );
      final playerInTeamAfterSwitch = find.descendant(
        of: teamTargetAfterSwitch, 
        matching: find.widgetWithText(Chip, 'Player 1')
      );
      expect(playerInTeamAfterSwitch, findsOneWidget);
    });
  });
}
