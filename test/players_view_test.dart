import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/views/players_view.dart';
import 'package:provider/provider.dart';

import 'players_view_test.mocks.dart';

// Generate mocks for the services
@GenerateMocks([DataService, AuthService])
void main() {
  late MockDataService mockDataService;
  late MockAuthService mockAuthService;

  // Helper to create the widget tree with providers.
  Widget createPlayersPage() {
    when(mockDataService.latestRoster).thenReturn(
      WeeklyRoster(id: 'roster1', date: '01/01/2024', playerIds: [], playerNames: [], numberOfTeams: 2)
    );
    when(mockDataService.fetchLatestRoster()).thenAnswer((_) async {});

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>.value(value: mockDataService),
        Provider<AuthService>.value(value: mockAuthService),
      ],
      child: const MaterialApp(
        home: PlayersPage(), 
      ),
    );
  }

  setUp(() {
    mockDataService = MockDataService();
    mockAuthService = MockAuthService();

    // Default stubs for services
    when(mockDataService.players).thenReturn([]);
    when(mockDataService.isLoadingPlayers).thenReturn(false);
    when(mockDataService.isLoadingRoster).thenReturn(false); // *** This was the missing stub ***
    when(mockDataService.fetchPlayers()).thenAnswer((_) async {});
    when(mockDataService.addPlayer(any)).thenAnswer((_) async => null); // Default to success
  });

  group('PlayersPage', () {
    testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
      when(mockDataService.isLoadingPlayers).thenReturn(true);

      await tester.pumpWidget(createPlayersPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays a list of players', (WidgetTester tester) async {
      final players = [
        Player(id: '1', name: 'Player One'),
        Player(id: '2', name: 'Player Two'),
      ];
      when(mockDataService.players).thenReturn(players);

      await tester.pumpWidget(createPlayersPage());
      await tester.pumpAndSettle();

      expect(find.text('Player One'), findsOneWidget);
      expect(find.text('Player Two'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('shows no list tiles when no players are available', (WidgetTester tester) async {
      when(mockDataService.players).thenReturn([]);

      await tester.pumpWidget(createPlayersPage());
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('can open dialog and add a new player successfully', (WidgetTester tester) async {
      await tester.pumpWidget(createPlayersPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      
      await tester.enterText(find.byType(TextField), 'New Player');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      verify(mockDataService.addPlayer('New Player')).called(1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Player "New Player" added.'), findsOneWidget);
    });

    testWidgets('shows error when adding an empty player name', (WidgetTester tester) async {
      when(mockDataService.addPlayer('')).thenAnswer((_) async => 'Player name cannot be empty.');

      await tester.pumpWidget(createPlayersPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      verify(mockDataService.addPlayer('')).called(1);
      expect(find.text('Failed to add player: Player name cannot be empty.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows error when adding a player name with only whitespace', (WidgetTester tester) async {
      const whitespaceName = '   ';
      when(mockDataService.addPlayer(whitespaceName)).thenAnswer((_) async => 'Player name cannot be empty.');

      await tester.pumpWidget(createPlayersPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), whitespaceName);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      verify(mockDataService.addPlayer(whitespaceName)).called(1);
      expect(find.text('Failed to add player: Player name cannot be empty.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows error snackbar if adding player fails on the server', (WidgetTester tester) async {
      when(mockDataService.addPlayer('Failing Player')).thenAnswer((_) async => 'Server error.');

      await tester.pumpWidget(createPlayersPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField), 'Failing Player');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      verify(mockDataService.addPlayer('Failing Player')).called(1);
      expect(find.text('Failed to add player: Server error.'), findsOneWidget);
    });
  });
}
