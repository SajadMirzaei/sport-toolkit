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

@GenerateMocks([DataService, LoginProvider, User])
void main() {
  late MockDataService mockDataService;
  late MockLoginProvider mockLoginProvider;
  late MockUser mockUser;

  setUp(() {
    mockDataService = MockDataService();
    mockLoginProvider = MockLoginProvider();
    mockUser = MockUser();

    when(mockDataService.fetchPlayers()).thenAnswer((_) async {});
    when(mockDataService.fetchLatestRoster()).thenAnswer((_) async {});
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

  Future<void> dragPlayerToTeam(
    WidgetTester tester,
    String playerName,
    String teamName,
  ) async {
    final playerChip = find.widgetWithText(Chip, playerName);
    final teamTarget = findDragTargetByText(teamName);
    final dragOffset =
        tester.getCenter(teamTarget) - tester.getCenter(playerChip);
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

      await dragPlayerToTeam(tester, 'Player 1', 'Team 1');

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

    testWidgets('can submit a valid team suggestion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      await dragPlayerToTeam(tester, 'Player 1', 'Team 1');
      await dragPlayerToTeam(tester, 'Player 2', 'Team 2');

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Submit Suggestion'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Submit'));
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

      await dragPlayerToTeam(tester, 'Player 1', 'Team 1');

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
          playerNames: ['Player 1', 'Player 2', 'Player 3'],
          playerIds: ['p1', 'p2', 'p3'],
          numberOfTeams: 2,
        ),
      );

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      await dragPlayerToTeam(tester, 'Player 1', 'Team 1');
      await dragPlayerToTeam(tester, 'Player 2', 'Team 1');
      await dragPlayerToTeam(tester, 'Player 3', 'Team 1');

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
          playerNames: ['Player 1', 'Player 2', 'Player 3'],
          playerIds: ['p1', 'p2', 'p3'],
          numberOfTeams: 2,
        ),
      );

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      await dragPlayerToTeam(tester, 'Player 1', 'Team 1');
      await dragPlayerToTeam(tester, 'Player 2', 'Team 1');
      await dragPlayerToTeam(tester, 'Player 3', 'Team 2');

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows success snackbar on successful submission', (
      WidgetTester tester,
    ) async {
      when(
        mockDataService.submitSuggestedTeam(any, any, any, any),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      await dragPlayerToTeam(tester, 'Player 1', 'Team 1');
      await dragPlayerToTeam(tester, 'Player 2', 'Team 2');

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Team suggestion submitted successfully! Your vote has been counted.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows duplicate suggestion dialog on duplicate submission', (
      WidgetTester tester,
    ) async {
      when(
        mockDataService.submitSuggestedTeam(any, any, any, any),
      ).thenAnswer((_) async => 'DUPLICATE');

      await tester.pumpWidget(createTeamFormationPage(tester));
      await tester.pumpAndSettle();

      await dragPlayerToTeam(tester, 'Player 1', 'Team 1');
      await dragPlayerToTeam(tester, 'Player 2', 'Team 2');

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit Team Suggestion'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Suggestion Already Exists'), findsOneWidget);
      expect(
        find.text(
          'This team combination has already been suggested. Your submission has been counted as an upvote.',
        ),
        findsOneWidget,
      );
    });
  });
}
