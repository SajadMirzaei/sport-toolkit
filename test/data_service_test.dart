import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DataService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DataService dataService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataService = DataService.test(fakeFirestore);
    });

    test('does not cancel upvote when submitting a duplicate of an already-upvoted team', () async {
      // 1. Arrange
      const rosterId = 'roster1';
      const userId = 'user123';
      final players = [
        Player(id: 'p1', name: 'Player 1'),
        Player(id: 'p2', name: 'Player 2'),
      ];
      final teams = [
        [players[0]],
        [players[1]],
      ];
      final teamHash = dataService.generateTeamHash(teams);
      final rosterRef = fakeFirestore.collection('weekly_rosters').doc(rosterId);
      final suggestionId = 'suggestion1';

      // 2. Arrange: Create a pre-existing suggestion in the fake database
      await fakeFirestore.collection('suggested_teams').doc(suggestionId).set({
        'rosterId': rosterRef,
        'teamHash': teamHash,
        'submittedBy': 'Another User',
        'upvotes': 1,
        'downvotes': 0,
        'votedBy': {userId: 'up'}, // The user has already upvoted this
        'teams': {
          'team_0': [{'id': 'p1', 'name': 'Player 1'}],
          'team_1': [{'id': 'p2', 'name': 'Player 2'}],
        },
      });

      // 3. Act: The user submits the exact same team again
      final result = await dataService.submitSuggestedTeam(teams, rosterId, 'Test User', userId);

      // 4. Assert
      expect(result, 'DUPLICATE', reason: "The service should detect the duplicate.");

      // 5. Assert: Check the database state directly
      final doc = await fakeFirestore.collection('suggested_teams').doc(suggestionId).get();
      final suggestion = SuggestedTeam.fromFirestore(doc);

      expect(suggestion.upvotes, 1, reason: "The upvote count should not change.");
      expect(suggestion.votedBy[userId], 'up', reason: "The user's vote should remain 'up'.");
    });
  });
}
