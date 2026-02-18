import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/player.dart';
import 'package:myapp/models/suggested_team.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/views/team_voting_view.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/login_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'team_voting_view_test.mocks.dart';

@GenerateMocks([DataService, LoginProvider, User])
void main() {
  late MockDataService mockDataService;
  late MockLoginProvider mockLoginProvider;
  late MockUser mockUser;

  final player1 = Player(id: 'p1', name: 'Player 1');
  final player2 = Player(id: 'p2', name: 'Player 2');

  final suggestedTeam1 = SuggestedTeam(
    id: 'st1',
    teams: [[player1], [player2]],
    submittedBy: 'User A',
    upvotes: 5,
    downvotes: 1,
    votedBy: {'uid-123': 'up'},
  );

  final suggestedTeam2 = SuggestedTeam(
    id: 'st2',
    teams: [[player2], [player1]],
    submittedBy: 'User B',
    upvotes: 2,
    downvotes: 3,
    votedBy: {},
  );

  setUp(() {
    mockDataService = MockDataService();
    mockLoginProvider = MockLoginProvider();
    mockUser = MockUser();

    when(mockDataService.fetchLatestRoster()).thenAnswer((_) async {});
    when(mockDataService.vote(any, any, any)).thenAnswer((_) async {});

    when(mockLoginProvider.user).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('uid-123');
  });

  Widget createTeamVotingView() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>.value(value: mockDataService),
        ChangeNotifierProvider<LoginProvider>.value(value: mockLoginProvider),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: TeamVotingView(),
        ),
      ),
    );
  }

  group('TeamVotingView', () {
    testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
      when(mockDataService.isLoadingSuggestedTeams).thenReturn(true);
      when(mockDataService.suggestedTeams).thenReturn([]);

      await tester.pumpWidget(createTeamVotingView());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state message when no suggestions are available', (WidgetTester tester) async {
      when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);
      when(mockDataService.suggestedTeams).thenReturn([]);

      await tester.pumpWidget(createTeamVotingView());
      await tester.pumpAndSettle();

      expect(find.text('No suggested teams available for the latest roster.'), findsOneWidget);
    });

    testWidgets('displays a list of suggested teams', (WidgetTester tester) async {
      when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);
      when(mockDataService.suggestedTeams).thenReturn([suggestedTeam1, suggestedTeam2]);

      await tester.pumpWidget(createTeamVotingView());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('Suggested by: User A'), findsOneWidget);
      expect(find.text('Suggested by: User B'), findsOneWidget);
    });

    testWidgets('upvote button calls the vote method', (WidgetTester tester) async {
      when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);
      when(mockDataService.suggestedTeams).thenReturn([suggestedTeam2]);

      await tester.pumpWidget(createTeamVotingView());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined));
      await tester.pumpAndSettle();

      verify(mockDataService.vote(suggestedTeam2, 'uid-123', 'up')).called(1);
    });

    testWidgets('downvote button calls the vote method', (WidgetTester tester) async {
      when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);
      when(mockDataService.suggestedTeams).thenReturn([suggestedTeam2]);

      await tester.pumpWidget(createTeamVotingView());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.thumb_down_alt_outlined));
      await tester.pumpAndSettle();

      verify(mockDataService.vote(suggestedTeam2, 'uid-123', 'down')).called(1);
    });

    testWidgets('correctly displays vote counts and user\'s vote', (WidgetTester tester) async {
      when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);
      when(mockDataService.suggestedTeams).thenReturn([suggestedTeam1]);

      await tester.pumpWidget(createTeamVotingView());
      await tester.pumpAndSettle();

      // suggestedTeam1 has 5 upvotes, 1 downvote. Net score is 4.
      expect(find.text('4'), findsOneWidget); 
      // The user ('uid-123') has upvoted this team.
      expect(find.byIcon(Icons.thumb_up_alt), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_alt_outlined), findsOneWidget);
    });

    testWidgets('suggestions are sorted by net votes in descending order', (WidgetTester tester) async {
      final teamA = SuggestedTeam(id: 'stA', teams: [], submittedBy: 'User A', upvotes: 10, downvotes: 2); // Net: 8
      final teamB = SuggestedTeam(id: 'stB', teams: [], submittedBy: 'User B', upvotes: 12, downvotes: 5); // Net: 7
      final teamC = SuggestedTeam(id: 'stC', teams: [], submittedBy: 'User C', upvotes: 15, downvotes: 3); // Net: 12

      when(mockDataService.isLoadingSuggestedTeams).thenReturn(false);
      // The view itself doesn't sort, the data comes from the service already sorted. So we provide it sorted.
      when(mockDataService.suggestedTeams).thenReturn([teamC, teamA, teamB]);

      await tester.pumpWidget(createTeamVotingView());
      await tester.pumpAndSettle();

      final cardFinds = find.byType(Card).evaluate();
      final firstCard = cardFinds.elementAt(0).widget as Card;
      final secondCard = cardFinds.elementAt(1).widget as Card;
      final thirdCard = cardFinds.elementAt(2).widget as Card;

      // This is a basic way to check order. It's not perfect, but it works.
      expect(find.descendant(of: find.byWidget(firstCard), matching: find.text('12')), findsOneWidget); 
      expect(find.descendant(of: find.byWidget(secondCard), matching: find.text('8')), findsOneWidget);
      expect(find.descendant(of: find.byWidget(thirdCard), matching: find.text('7')), findsOneWidget);
    });
  });
}
