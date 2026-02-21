
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/player.dart';
import 'package:myapp/models/weekly_roster.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/views/players_view.dart';

import 'players_view_test.mocks.dart';

// Helper function to create the widget tree for testing
Widget createPlayersPage(DataService dataService) {
  return ChangeNotifierProvider<DataService>.value(
    value: dataService,
    child: const MaterialApp(
      home: PlayersPage(),
    ),
  );
}

@GenerateMocks([DataService])
void main() {
  late MockDataService mockDataService;

  // Sample data
  final players = [
    Player(id: '1', name: 'Player 1'),
    Player(id: '2', name: 'Player 2'),
  ];
  final roster = WeeklyRoster(
    id: 'roster1',
    playerIds: {'1'}.toList(),
    playerNames: ['Player 1'],
    numberOfTeams: 3,
    date: '2024-01-01',
  );

  setUp(() {
    mockDataService = MockDataService();
    // Stub the getters and methods with default successful responses
    when(mockDataService.players).thenReturn(players);
    when(mockDataService.latestRoster).thenReturn(null);
    when(mockDataService.isLoadingPlayers).thenReturn(false);
    when(mockDataService.isLoadingRoster).thenReturn(false);
    when(mockDataService.fetchPlayers()).thenAnswer((_) async {});
    when(mockDataService.fetchLatestRoster()).thenAnswer((_) async {});
    when(mockDataService.addPlayer(any)).thenAnswer((_) async => null);
    when(mockDataService.submitRoster(any, any)).thenAnswer((_) async => null);
  });

  testWidgets('should show loading indicator while players are loading', (tester) async {
    when(mockDataService.isLoadingPlayers).thenReturn(true);
    await tester.pumpWidget(createPlayersPage(mockDataService));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('should display players and allow selection', (tester) async {
    await tester.pumpWidget(createPlayersPage(mockDataService));
    await tester.pumpAndSettle(); // Let the UI build

    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);

    // Tap to select a player
    await tester.tap(find.text('Player 1'));
    await tester.pumpAndSettle();

    // Verify selection
    final checkbox = tester.widget<CheckboxListTile>(find.byWidgetPredicate(
        (widget) => widget is CheckboxListTile && widget.title is Text && (widget.title as Text).data == 'Player 1'));
    expect(checkbox.value, isTrue);

    // Verify selected count chip
    expect(find.descendant(of: find.byType(Chip), matching: find.text('1')), findsOneWidget);

    // Tap to deselect
    await tester.tap(find.text('Player 1'));
    await tester.pumpAndSettle();
    final checkboxAfterDeselect = tester.widget<CheckboxListTile>(find.byWidgetPredicate(
        (widget) => widget is CheckboxListTile && widget.title is Text && (widget.title as Text).data == 'Player 1'));
    expect(checkboxAfterDeselect.value, isFalse);
    expect(find.descendant(of: find.byType(Chip), matching: find.text('0')), findsOneWidget);
  });

  testWidgets('should initialize selection from latest roster', (tester) async {
    when(mockDataService.latestRoster).thenReturn(roster);
    await tester.pumpWidget(createPlayersPage(mockDataService));
    await tester.pumpAndSettle();

    // Player 1 should be selected from the roster
    final checkbox = tester.widget<CheckboxListTile>(find.byWidgetPredicate(
        (widget) => widget is CheckboxListTile && widget.title is Text && (widget.title as Text).data == 'Player 1'));
    expect(checkbox.value, isTrue);

    // Number of teams should be from the roster
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('should allow changing the number of teams', (tester) async {
    await tester.pumpWidget(createPlayersPage(mockDataService));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    // Increment
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);

    // Decrement
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    // Should not go below 2
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('should add a new player through dialog', (tester) async {
    await tester.pumpWidget(createPlayersPage(mockDataService));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Dialog is shown
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'New Player');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    verify(mockDataService.addPlayer('New Player')).called(1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Player "New Player" added.'), findsOneWidget);
  });

  testWidgets('should show error when adding a player fails', (tester) async {
    when(mockDataService.addPlayer(any)).thenAnswer((_) async => 'Error');

    await tester.pumpWidget(createPlayersPage(mockDataService));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Fail Player');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to add player: Error'), findsOneWidget);
  });


  testWidgets('should submit roster and show success message', (tester) async {
    await tester.pumpWidget(createPlayersPage(mockDataService));
    await tester.pumpAndSettle();

    // Select a player to enable the button
    await tester.tap(find.text('Player 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit Roster for the Week'));
    await tester.pumpAndSettle();

    verify(mockDataService.submitRoster(['1'], 2)).called(1);
    expect(find.text('Weekly roster has been updated!'), findsOneWidget);
  });

  testWidgets('should show error when submitting roster fails', (tester) async {
    when(mockDataService.submitRoster(any, any)).thenAnswer((_) async => 'Submit Error');

    await tester.pumpWidget(createPlayersPage(mockDataService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Player 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit Roster for the Week'));
    await tester.pumpAndSettle();

    expect(find.text('Submit Error'), findsOneWidget);
  });

  testWidgets('should refresh data on pull-to-refresh', (tester) async {
    await tester.pumpWidget(createPlayersPage(mockDataService));
    await tester.pumpAndSettle();

    await tester.fling(find.text('Player 1'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    verify(mockDataService.fetchPlayers()).called(2); // Once in init, once on refresh
    verify(mockDataService.fetchLatestRoster()).called(2);
  });
}
