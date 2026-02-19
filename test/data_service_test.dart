import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DataService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DataService dataService;
    late Player p1, p2, p3, p4;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataService = DataService.test(fakeFirestore);
      p1 = Player(id: 'p1', name: 'Player 1');
      p2 = Player(id: 'p2', name: 'Player 2');
      p3 = Player(id: 'p3', name: 'Player 3');
      p4 = Player(id: 'p4', name: 'Player 4');
    });

    test('does not cancel upvote when submitting a duplicate of an already-upvoted team', () async {
      const rosterId = 'roster1';
      const userId = 'user123';
      final teams = [
        [p1],
        [p2],
      ];
      final teamHash = dataService.generateTeamHash(teams);
      final rosterRef = fakeFirestore.collection('weekly_rosters').doc(rosterId);
      const suggestionId = 'suggestion1';

      await fakeFirestore.collection('suggested_teams').doc(suggestionId).set({
        'rosterId': rosterRef,
        'teamHash': teamHash,
        'submittedBy': 'Another User',
        'upvotes': 1,
        'downvotes': 0,
        'votedBy': {userId: 'up'}, // The user has already upvoted this
        'teams': {
          'team_0': [p1.toJson()],
          'team_1': [p2.toJson()],
        },
      });

      final result = await dataService.submitSuggestedTeam(teams, rosterId, 'Test User', userId);

      expect(result, 'DUPLICATE');

      final doc = await fakeFirestore.collection('suggested_teams').doc(suggestionId).get();
      final suggestion = SuggestedTeam.fromFirestore(doc);

      expect(suggestion.upvotes, 1, reason: "The upvote count should not change.");
      expect(suggestion.votedBy[userId], 'up', reason: "The user's vote should remain 'up'.");
    });

    group('generateTeamHash', () {
      test('is deterministic for the same team structure', () {
        final teams1 = [[p1, p2], [p3, p4]];
        final teams2 = [[p1, p2], [p3, p4]];
        expect(dataService.generateTeamHash(teams1), dataService.generateTeamHash(teams2));
      });

      test('is the same regardless of player order within teams', () {
        final teams1 = [[p1, p2], [p3, p4]];
        final teams2 = [[p2, p1], [p4, p3]];
        expect(dataService.generateTeamHash(teams1), dataService.generateTeamHash(teams2));
      });

      test('is the same regardless of team order', () {
        final teams1 = [[p1, p2], [p3, p4]];
        final teams2 = [[p3, p4], [p1, p2]];
        expect(dataService.generateTeamHash(teams1), dataService.generateTeamHash(teams2));
      });

      test('is different for different team structures', () {
        final teams1 = [[p1, p3], [p2, p4]]; // p3 and p2 swapped
        final teams2 = [[p1, p2], [p3, p4]];
        expect(dataService.generateTeamHash(teams1), isNot(dataService.generateTeamHash(teams2)));
      });
    });

    group('vote', () {
      late DocumentReference<Map<String, dynamic>> suggestionRef;
      late SuggestedTeam initialSuggestion;
      const userId = 'user1';

      setUp(() async {
        suggestionRef = fakeFirestore.collection('suggested_teams').doc('suggestion1');
        await suggestionRef.set({
          'rosterId': fakeFirestore.collection('weekly_rosters').doc('roster1'),
          'teamHash': 'hash1',
          'submittedBy': 'Submitter',
          'upvotes': 1,
          'downvotes': 1,
          'votedBy': {'submitter_id': 'up', 'user2': 'down'},
          'teams': {},
        });
        final initialDoc = await suggestionRef.get();
        initialSuggestion = SuggestedTeam.fromFirestore(initialDoc);
      });

      test('first time upvote works correctly', () async {
        await dataService.vote(initialSuggestion, userId, 'up');
        final finalDoc = await suggestionRef.get();
        final finalSuggestion = SuggestedTeam.fromFirestore(finalDoc);

        expect(finalSuggestion.upvotes, initialSuggestion.upvotes + 1);
        expect(finalSuggestion.votedBy[userId], 'up');
      });

      test('retracting an upvote works correctly', () async {
        // First, upvote
        await dataService.vote(initialSuggestion, userId, 'up');
        final midDoc = await suggestionRef.get();
        final midSuggestion = SuggestedTeam.fromFirestore(midDoc);

        // Then, retract the upvote
        await dataService.vote(midSuggestion, userId, 'up');
        final finalDoc = await suggestionRef.get();
        final finalSuggestion = SuggestedTeam.fromFirestore(finalDoc);

        expect(finalSuggestion.upvotes, initialSuggestion.upvotes);
        expect(finalSuggestion.votedBy.containsKey(userId), isFalse);
      });

      test('changing vote from down to up works correctly', () async {
        // First, downvote
        await dataService.vote(initialSuggestion, userId, 'down');
        final midDoc = await suggestionRef.get();
        final midSuggestion = SuggestedTeam.fromFirestore(midDoc);

        expect(midSuggestion.downvotes, initialSuggestion.downvotes + 1);

        // Then, change to upvote
        await dataService.vote(midSuggestion, userId, 'up');
        final finalDoc = await suggestionRef.get();
        final finalSuggestion = SuggestedTeam.fromFirestore(finalDoc);

        expect(finalSuggestion.upvotes, initialSuggestion.upvotes + 1);
        expect(finalSuggestion.downvotes, initialSuggestion.downvotes);
        expect(finalSuggestion.votedBy[userId], 'up');
      });
    });
  });
}
