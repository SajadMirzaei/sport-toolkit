import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/player.dart';
import 'package:myapp/models/weekly_roster.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/views/team_formation_view.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'team_formation_view_test.mocks.dart';

@GenerateMocks([DataService, LoginProvider, User, TabController])
void main() {
  late MockDataService mockDataService;
  late MockLoginProvider mockLoginProvider;
  late MockUser mockUser;

  setUp(() {
    mockDataService = MockDataService();
    mockLoginProvider = MockLoginProvider();
    mockUser = MockUser();

    when(mockDataService.fetchPlayers()).thenAnswer((_) async {});
    when(mockDataService.fetchLatestRoster(forceFromServer: anyNamed('forceFromServer'))).thenAnswer((_) async {});
    when(
      mockDataService.submitSuggestedTeam(any, any, any, any),
    ).thenAnswer((_) async => null);

    when(mockDataService.isLoadingRoster).thenReturn(false);
    when(mockDataService.players).thenReturn([
      Player(id: 'p1', name: 'Player 1'),
      Player(id: 'p2', name: 'Player 2'),
    ]);
    when(mockDataService.latestRoster).thenReturn(
      WeeklyRoster(
        id: '1',
        date: '2023-10-27',
        preciseDate: DateTime(2023, 10, 27, 10, 0, 0),
        playerNames: ['Player 1', 'Player 2'],
        playerIds: ['p1', 'p2'],
        numberOfTeams: 2,
      ),
    );
    when(mockDataService.suggestedTeams).thenReturn([]);

    when(mockLoginProvider.user).thenReturn(mockUser);
    when(mockUser.displayName).thenReturn('Test User');
    when(mockUser.uid).thenReturn('uid-123');
  });

  Widget createTeamFormationPage(WidgetTester tester) {
    tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ChangeNotifierProvider<LoginProvider>.value(value: mockLoginProvider),
      ],
      child: const MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(body: TeamFormationPage()),
        ),
      ),
    );
  }

  Finder findDragTargetByText(String text) {
    return find.byWidgetPredicate(
      (Widget widget) =>
          widget is DragTarget &&
          find
              .descendant(of: find.byWidget(widget), matching: find.text(text))
              .evaluate()
              .isNotEmpty,
    );
  }

  Future<void> dragPlayerToTarget(
    WidgetTester tester,
    String playerName,
    Finder target,
  ) async {
    final playerChip = find.widgetWithText(Chip, playerName);
    final dragOffset =
        tester.getCenter(target) - tester.getCenter(playerChip);
    await tester.drag(playerChip, dragOffset);
    await tester.pumpAndSettle();
  }


  group('TeamFormationPage', () {
    testWidgets('shows loading indicator when loading', (
      WidgetTester tester,
    ) async {
      when(mockDataService.isLoadingRoster).thenReturn(true);
      await tester.pumpWidget(createTeamFormationPage(tester));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows initial UI elements and unassigned players', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      expect(find.text('Unassigned Players'), findsOneWidget);
      expect(find.text('Team 1'), findsOneWidget);
      expect(find.text('Team 2'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
        findsOneWidget,
      );

      final unassignedPlayersBox = findDragTargetByText('Unassigned Players');
      expect(
        find.descendant(
          of: unassignedPlayersBox,
          matching: find.text('Player 1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: unassignedPlayersBox,
          matching: find.text('Player 2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('can drag a player to a team', (WidgetTester tester) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final teamTarget = findDragTargetByText('Team 1');
      await dragPlayerToTarget(tester, 'Player 1', teamTarget);

      final team1Target = findDragTargetByText('Team 1');
      expect(
        find.descendant(of: team1Target, matching: find.text('Player 1')),
        findsOneWidget,
      );
      final unassignedPlayersBox = findDragTargetByText('Unassigned Players');
      expect(
        find.descendant(
          of: unassignedPlayersBox,
          matching: find.text('Player 1'),
        ),
        findsNothing,
      );
    });

    testWidgets('can drag a player from a team back to unassigned', (
      WidgetTester tester) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final teamTarget = findDragTargetByText('Team 1');
      await dragPlayerToTarget(tester, 'Player 1', teamTarget);
      await tester.pumpAndSettle(); // Settle after first drag

      final unassignedTarget = findDragTargetByText('Unassigned Players');
      await dragPlayerToTarget(tester, 'Player 1', unassignedTarget);
      await tester.pumpAndSettle(); // Settle after second drag

       final unassignedPlayersBox = findDragTargetByText('Unassigned Players');
      expect(
        find.descendant(
          of: unassignedPlayersBox,
          matching: find.text('Player 1'),
        ),
        findsOneWidget,
      );
      final team1Target = findDragTargetByText('Team 1');
      expect(
        find.descendant(of: team1Target, matching: find.text('Player 1')),
        findsNothing,
      );
    });


    testWidgets('pull to refresh re-initializes players and teams', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      // Verify initial state
      verify(mockDataService.fetchPlayers()).called(1);
      verify(mockDataService.fetchLatestRoster()).called(1);

      // Simulate pull to refresh
      await tester.fling(find.text('Unassigned Players'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify that the data is fetched again
      verify(mockDataService.fetchPlayers()).called(1);
      verify(mockDataService.fetchLatestRoster()).called(1);
    });

    testWidgets('shows error snackbar on submission failure', (
      WidgetTester tester,
    ) async {
      when(
        mockDataService.submitSuggestedTeam(any, any, any, any),
      ).thenThrow(Exception('An error occurred'));

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(
        find.text('An error occurred while submitting. Please try again.'),
        findsOneWidget,
      );
    });


    testWidgets('can submit a valid team suggestion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Submit Suggestion'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      verify(
        mockDataService.submitSuggestedTeam(any, '1', 'Test User', 'uid-123'),
      ).called(1);
    });

    testWidgets('shows snackbar if not all players are assigned', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.text('All players must be assigned to a team before submitting.'),
        findsOneWidget,
      );
    });

    testWidgets('shows snackbar if team sizes differ by more than one', (
      WidgetTester tester,
    ) async {
      when(mockDataService.players).thenReturn([
        Player(id: 'p1', name: 'Player 1'),
        Player(id: 'p2', name: 'Player 2'),
        Player(id: 'p3', name: 'Player 3'),
      ]);
      when(mockDataService.latestRoster).thenReturn(
        WeeklyRoster(
          id: '1',
          date: '2023-10-27',
          preciseDate: DateTime(2023, 10, 27, 10, 0, 0),
          playerNames: ['Player 1', 'Player 2', 'Player 3'],
          playerIds: ['p1', 'p2', 'p3'],
          numberOfTeams: 2,
        ),
      );

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team1Target);
      await dragPlayerToTarget(tester, 'Player 3', team1Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.text(
          'Teams are not balanced. Player counts per team cannot differ by more than one.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('allows submission if team sizes differ by one', (
      WidgetTester tester,
    ) async {
      when(mockDataService.players).thenReturn([
        Player(id: 'p1', name: 'Player 1'),
        Player(id: 'p2', name: 'Player 2'),
        Player(id: 'p3', name: 'Player 3'),
      ]);
      when(mockDataService.latestRoster).thenReturn(
        WeeklyRoster(
          id: '1',
          date: '2023-10-27',
          preciseDate: DateTime(2023, 10, 27, 10, 0, 0),
          playerNames: ['Player 1', 'Player 2', 'Player 3'],
          playerIds: ['p1', 'p2', 'p3'],
          numberOfTeams: 2,
        ),
      );

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team1Target);
      await dragPlayerToTarget(tester, 'Player 3', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows success snackbar and switches tab on successful submission', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Team suggestion submitted successfully! Your vote has been counted.',
        ),
        findsOneWidget,
      );

      final tabController = DefaultTabController.of(
        tester.element(find.byType(TeamFormationPage)),
      );
      expect(tabController.index, 1);
    });

    testWidgets(
        'shows duplicate suggestion dialog and switches tab on duplicate submission',
        (WidgetTester tester) async {
      when(
        mockDataService.submitSuggestedTeam(any, any, any, any),
      ).thenAnswer((_) async => 'DUPLICATE');

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Suggestion Already Exists'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();

      final tabController = DefaultTabController.of(
        tester.element(find.byType(TeamFormationPage)),
      );
      expect(tabController.index, 1);
    });

    testWidgets('handles null roster', (WidgetTester tester) async {
      when(mockDataService.latestRoster).thenReturn(WeeklyRoster(
        id: '',
        date: 'No roster submitted yet',
        preciseDate: DateTime.now(),
        playerNames: [],
        playerIds: [],
        numberOfTeams: 2
      ));

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      expect(find.text('Unassigned Players'), findsOneWidget);
      expect(find.text('Team 1'), findsOneWidget);
      expect(find.text('Team 2'), findsOneWidget);
      expect(find.text('All players have been assigned!'), findsOneWidget);
    });

    testWidgets('shows snackbar if user is not logged in', (
      WidgetTester tester,
    ) async {
      when(mockLoginProvider.user).thenReturn(null);

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.text('You must be logged in to submit a suggestion.'),
          findsOneWidget);
    });

    testWidgets('shows snackbar if rosterId is missing', (
      WidgetTester tester,
    ) async {
      when(mockDataService.latestRoster).thenReturn(
        WeeklyRoster(
          id: '',
          date: '2023-10-27',
          preciseDate: DateTime(2023, 10, 27, 10, 0, 0),
          playerNames: ['Player 1', 'Player 2'],
          playerIds: ['p1', 'p2'],
          numberOfTeams: 2,
        ),
      );

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not find a roster to link the suggestion to.'),
          findsOneWidget);
    });

    testWidgets('does not submit when cancelling the dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockDataService.submitSuggestedTeam(any, any, any, any));
    });

    testWidgets('shows generic error snackbar on other submission error', (
      WidgetTester tester,
    ) async {
      when(
        mockDataService.submitSuggestedTeam(any, any, any, any),
      ).thenAnswer((_) async => 'UNKNOWN_ERROR');

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to submit suggestion: UNKNOWN_ERROR'),
          findsOneWidget);
    });

    testWidgets('shows stale roster dialog and aborts submission if roster changes', (WidgetTester tester) async {
      // 1. SETUP
      final initialRoster = WeeklyRoster(
        id: 'roster1',
        date: '2023-10-27',
        preciseDate: DateTime(2023, 10, 27, 10, 0, 0),
        playerNames: ['Player 1', 'Player 2'],
        playerIds: ['p1', 'p2'],
        numberOfTeams: 2,
      );
      final updatedRoster = WeeklyRoster(
        id: 'roster2',
        date: '2023-10-27', // Same date, different time
        preciseDate: DateTime(2023, 10, 27, 11, 0, 0),
        playerNames: ['Player 1', 'Player 2', 'Player 3'],
        playerIds: ['p1', 'p2', 'p3'],
        numberOfTeams: 2,
      );

      // Initial load uses the first roster
      when(mockDataService.latestRoster).thenReturn(initialRoster);
      
      // When the submission happens, the forced fetch will "load" the new roster
      when(mockDataService.fetchLatestRoster(forceFromServer: true)).thenAnswer((_) async {
        // After this call, the service should report the new roster
        when(mockDataService.latestRoster).thenReturn(updatedRoster);
      });

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      // 2. ARRANGE - Make the team setup valid for submission
      final team1Target = findDragTargetByText('Team 1');
      final team2Target = findDragTargetByText('Team 2');
      await dragPlayerToTarget(tester, 'Player 1', team1Target);
      await dragPlayerToTarget(tester, 'Player 2', team2Target);

      // 3. ACT - Tap submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'));
      await tester.pumpAndSettle();

      // 4. ASSERT
      // The stale roster dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Roster Has Changed'), findsOneWidget);

      // Submission should not have happened
      verifyNever(mockDataService.submitSuggestedTeam(any, any, any, any));
      
      // Dismiss the dialog
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      
      // The page should have re-initialized
      verify(mockDataService.fetchLatestRoster(forceFromServer: false)).called(2);
    });

  });
}
