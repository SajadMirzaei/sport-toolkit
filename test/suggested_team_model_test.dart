import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/player.dart';
import 'package:myapp/models/suggested_team.dart';

import 'suggested_team_model_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('SuggestedTeam Model', () {
    test('should correctly serialize to and deserialize from Firestore', () {
      // 1. Create mock objects
      final mockDocumentSnapshot = MockDocumentSnapshot();
      final player1 = Player(id: 'p1', name: 'Player 1');
      final player2 = Player(id: 'p2', name: 'Player 2');
      final player3 = Player(id: 'p3', name: 'Player 3');
      final player4 = Player(id: 'p4', name: 'Player 4');

      // 2. Define the original SuggestedTeam object
      final originalSuggestedTeam = SuggestedTeam(
        id: 'testId',
        teams: [
          [player1, player2],
          [player3, player4]
        ],
        submittedBy: 'testUser',
        upvotes: 10,
        downvotes: 2,
        votedBy: {'user1': 'up', 'user2': 'down'},
        teamHash: 'testHash',
      );

      // 3. Serialize the object to a JSON map
      final json = originalSuggestedTeam.toJson();

      // 4. Mock the DocumentSnapshot's behavior
      when(mockDocumentSnapshot.id).thenReturn(originalSuggestedTeam.id);
      when(mockDocumentSnapshot.data()).thenReturn(json);

      // 5. Deserialize the JSON map back into a SuggestedTeam object
      final deserializedSuggestedTeam =
          SuggestedTeam.fromFirestore(mockDocumentSnapshot);

      // 6. Verify that the deserialized object matches the original
      expect(deserializedSuggestedTeam.id, originalSuggestedTeam.id);
      expect(
          deserializedSuggestedTeam.submittedBy, originalSuggestedTeam.submittedBy);
      expect(deserializedSuggestedTeam.upvotes, originalSuggestedTeam.upvotes);
      expect(deserializedSuggestedTeam.downvotes, originalSuggestedTeam.downvotes);
      expect(deserializedSuggestedTeam.votedBy, originalSuggestedTeam.votedBy);
      expect(deserializedSuggestedTeam.teamHash, originalSuggestedTeam.teamHash);

      // 7. Deep compare the list of teams and players
      expect(deserializedSuggestedTeam.teams.length,
          originalSuggestedTeam.teams.length);
      for (var i = 0; i < originalSuggestedTeam.teams.length; i++) {
        expect(deserializedSuggestedTeam.teams[i].length,
            originalSuggestedTeam.teams[i].length);
        for (var j = 0; j < originalSuggestedTeam.teams[i].length; j++) {
          expect(deserializedSuggestedTeam.teams[i][j].id,
              originalSuggestedTeam.teams[i][j].id);
          expect(deserializedSuggestedTeam.teams[i][j].name,
              originalSuggestedTeam.teams[i][j].name);
        }
      }
    });
  });
}
