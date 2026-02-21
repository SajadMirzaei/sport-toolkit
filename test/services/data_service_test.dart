import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// --- Mock Firebase Setup ---

void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();
}

void main() {
  setupFirebaseAuthMocks();

  group('DataService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DataService dataService;
    late Player p1, p2, p3, p4;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      dataService = DataService.test(fakeFirestore);
      p1 = Player(id: 'p1', name: 'Player 1');
      p2 = Player(id: 'p2', name: 'Player 2');
      p3 = Player(id: 'p3', name: 'Player 3');
      p4 = Player(id: 'p4', name: 'Player 4');

      await fakeFirestore.collection('players').doc(p1.id).set(p1.toJson());
      await fakeFirestore.collection('players').doc(p2.id).set(p2.toJson());
      await fakeFirestore.collection('players').doc(p3.id).set(p3.toJson());
      await fakeFirestore.collection('players').doc(p4.id).set(p4.toJson());
    });

    test(
      'does not cancel upvote when submitting a duplicate of an already-upvoted team',
      () async {
        const rosterId = 'roster1';
        const userId = 'user123';
        final teams = [
          [p1],
          [p2],
        ];
        final teamHash = dataService.generateTeamHash(teams);
        final rosterRef = fakeFirestore
            .collection('weekly_rosters')
            .doc(rosterId);
        const suggestionId = 'suggestion1';

        await fakeFirestore.collection('suggested_teams').doc(suggestionId).set(
          {
            'rosterId': rosterRef,
            'teamHash': teamHash,
            'submittedBy': 'Another User',
            'upvotes': 1,
            'downvotes': 0,
            'votedBy': {userId: 'up'},
            'teams': {
              'team_0': [p1.toJson()],
              'team_1': [p2.toJson()],
            },
          },
        );
        await fakeFirestore.collection('weekly_rosters').doc(rosterId).set({
          'date': Timestamp.now(),
          'present_players': [p1.id, p2.id],
          'number_of_teams': 2,
        });
        await dataService.fetchLatestRoster();

        final result = await dataService.submitSuggestedTeam(
          teams,
          rosterId,
          'Test User',
          userId,
        );

        expect(result, 'DUPLICATE');
        final doc =
            await fakeFirestore
                .collection('suggested_teams')
                .doc(suggestionId)
                .get();
        final suggestion = SuggestedTeam.fromFirestore(doc);
        expect(suggestion.upvotes, 1);
        expect(suggestion.votedBy[userId], 'up');
      },
    );

    group('generateTeamHash', () {
      test('is deterministic for the same team structure', () {
        final teams1 = [
          [p1, p2],
          [p3, p4],
        ];
        final teams2 = [
          [p1, p2],
          [p3, p4],
        ];
        expect(
          dataService.generateTeamHash(teams1),
          dataService.generateTeamHash(teams2),
        );
      });

      test('is the same regardless of player order within teams', () {
        final teams1 = [
          [p1, p2],
          [p3, p4],
        ];
        final teams2 = [
          [p2, p1],
          [p4, p3],
        ];
        expect(
          dataService.generateTeamHash(teams1),
          dataService.generateTeamHash(teams2),
        );
      });

      test('is the same regardless of team order', () {
        final teams1 = [
          [p1, p2],
          [p3, p4],
        ];
        final teams2 = [
          [p3, p4],
          [p1, p2],
        ];
        expect(
          dataService.generateTeamHash(teams1),
          dataService.generateTeamHash(teams2),
        );
      });

      test('is different for different team structures', () {
        final teams1 = [
          [p1, p3],
          [p2, p4],
        ];
        final teams2 = [
          [p1, p2],
          [p3, p4],
        ];
        expect(
          dataService.generateTeamHash(teams1),
          isNot(dataService.generateTeamHash(teams2)),
        );
      });
    });

    group('vote', () {
      late DocumentReference<Map<String, dynamic>> suggestionRef;
      late SuggestedTeam initialSuggestion;
      const userId = 'user1';

      setUp(() async {
        suggestionRef = fakeFirestore
            .collection('suggested_teams')
            .doc('suggestion1');
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
        await dataService.vote(initialSuggestion, 'submitter_id', 'up');
        final finalDoc = await suggestionRef.get();
        final finalSuggestion = SuggestedTeam.fromFirestore(finalDoc);
        expect(finalSuggestion.upvotes, initialSuggestion.upvotes - 1);
        expect(finalSuggestion.votedBy.containsKey('submitter_id'), isFalse);
      });

      test('changing vote from down to up works correctly', () async {
        await dataService.vote(initialSuggestion, 'user2', 'up');
        final finalDoc = await suggestionRef.get();
        final finalSuggestion = SuggestedTeam.fromFirestore(finalDoc);
        expect(finalSuggestion.upvotes, initialSuggestion.upvotes + 1);
        expect(finalSuggestion.downvotes, initialSuggestion.downvotes - 1);
        expect(finalSuggestion.votedBy['user2'], 'up');
      });

      test('retracting a downvote works correctly', () async {
        await dataService.vote(initialSuggestion, 'user2', 'down');
        final finalDoc = await suggestionRef.get();
        final finalSuggestion = SuggestedTeam.fromFirestore(finalDoc);
        expect(finalSuggestion.downvotes, initialSuggestion.downvotes - 1);
        expect(finalSuggestion.votedBy.containsKey('user2'), isFalse);
      });

      test('changing vote from up to down works correctly', () async {
        await dataService.vote(initialSuggestion, 'submitter_id', 'down');
        final finalDoc = await suggestionRef.get();
        final finalSuggestion = SuggestedTeam.fromFirestore(finalDoc);
        expect(finalSuggestion.downvotes, initialSuggestion.downvotes + 1);
        expect(finalSuggestion.upvotes, initialSuggestion.upvotes - 1);
        expect(finalSuggestion.votedBy['submitter_id'], 'down');
      });
    });

    group('Player Management', () {
      test('addPlayer handles empty name', () async {
        final result = await dataService.addPlayer('  ');
        expect(result, 'Player name cannot be empty.');
      });

      test('addPlayer adds a player successfully', () async {
        final result = await dataService.addPlayer('New Player');
        expect(result, isNull);
        final querySnapshot =
            await fakeFirestore
                .collection('players')
                .where('name', isEqualTo: 'New Player')
                .get();
        expect(querySnapshot.docs.length, 1);
        expect(dataService.players.any((p) => p.name == 'New Player'), isTrue);
      });
    });

    group('Roster Management', () {
      test('fetchLatestRoster loads roster and player names', () async {
        await fakeFirestore.collection('weekly_rosters').add({
          'present_players': ['p1', 'p2'],
          'date': Timestamp.now(),
          'number_of_teams': 2,
        });
        await dataService.fetchLatestRoster();
        expect(dataService.latestRoster, isNotNull);
        expect(dataService.latestRoster!.playerIds, containsAll(['p1', 'p2']));
        expect(
          dataService.latestRoster!.playerNames,
          containsAll(['Player 1', 'Player 2']),
        );
      });

      test('fetchLatestRoster handles no roster found', () async {
        await dataService.fetchLatestRoster();
        expect(dataService.latestRoster, isNotNull);
        expect(dataService.latestRoster!.date, 'No roster submitted yet');
        expect(dataService.players, isEmpty);
      });

      test('submitRoster with no players returns error', () async {
        final result = await dataService.submitRoster([], 2);
        expect(result, 'Please select at least one player.');
      });

      test('submitRoster saves a new roster', () async {
        final playerIds = ['p1', 'p2'];
        final result = await dataService.submitRoster(playerIds, 2);
        expect(result, isNull);
        final querySnapshot =
            await fakeFirestore.collection('weekly_rosters').get();
        expect(querySnapshot.docs.length, 1);
        final rosterData = querySnapshot.docs.first.data();
        expect(rosterData['present_players'], playerIds);
        expect(rosterData['number_of_teams'], 2);
      });

      test('submitRoster updates an existing roster', () async {
        final initialDoc = await fakeFirestore.collection('weekly_rosters').add(
          {
            'date': Timestamp.now(),
            'present_players': ['p1'],
            'number_of_teams': 1,
          },
        );
        await dataService.fetchLatestRoster();
        expect(dataService.latestRoster!.id, initialDoc.id);
        final updatedPlayerIds = ['p1', 'p2', 'p3'];
        final result = await dataService.submitRoster(updatedPlayerIds, 3);
        expect(result, isNull);
        final allRosters =
            await fakeFirestore.collection('weekly_rosters').get();
        expect(allRosters.docs.length, 1);
        final updatedDoc =
            await fakeFirestore
                .collection('weekly_rosters')
                .doc(initialDoc.id)
                .get();
        expect(updatedDoc.data()!['present_players'], updatedPlayerIds);
        expect(updatedDoc.data()!['number_of_teams'], 3);
      });
    });

    group('fetchPlayers', () {
      test('fetches players from firestore and sorts them by name', () async {
        await fakeFirestore.collection('players').doc('p_c').set({
          'name': 'Charlie',
        });
        await fakeFirestore.collection('players').doc('p_a').set({
          'name': 'Alice',
        });
        await dataService.fetchPlayers();
        expect(dataService.players.length, 6);
        expect(dataService.players[0].name, 'Alice');
        expect(dataService.players[1].name, 'Charlie');
        expect(dataService.players[2].name, 'Player 1');
      });
    });

    group('fetchSuggestedTeams', () {
      test('fetches and sorts suggested teams for a roster', () async {
        final rosterRef = fakeFirestore
            .collection('weekly_rosters')
            .doc('roster1');
        await rosterRef.set({
          'date': Timestamp.now(),
          'present_players': [],
          'number_of_teams': 2,
        });
        await dataService.fetchLatestRoster();
        expect(dataService.latestRoster!.id, 'roster1');
        await fakeFirestore.collection('suggested_teams').add({
          'rosterId': rosterRef,
          'upvotes': 5,
          'downvotes': 1,
          'teamHash': 'a',
          'teams': {},
        });
        await fakeFirestore.collection('suggested_teams').add({
          'rosterId': rosterRef,
          'upvotes': 10,
          'downvotes': 8,
          'teamHash': 'b',
          'teams': {},
        });
        await fakeFirestore.collection('suggested_teams').add({
          'rosterId': rosterRef,
          'upvotes': 8,
          'downvotes': 2,
          'teamHash': 'c',
          'teams': {},
        });
        await dataService.fetchSuggestedTeams();
        expect(dataService.suggestedTeams.length, 3);
        expect(dataService.suggestedTeams[0].teamHash, 'c');
        expect(dataService.suggestedTeams[1].teamHash, 'a');
        expect(dataService.suggestedTeams[2].teamHash, 'b');
      });

      test('clears teams if no roster is present', () async {
        dataService = DataService.test(fakeFirestore);
        dataService.suggestedTeams.add(
          SuggestedTeam(
            id: 's1',
            teams: [],
            submittedBy: '',
            upvotes: 1,
            downvotes: 0,
            votedBy: {},
            teamHash: '',
          ),
        );
        expect(dataService.suggestedTeams, isNotEmpty);
        await dataService.fetchSuggestedTeams();
        expect(dataService.suggestedTeams, isEmpty);
      });
    });

    group('submitSuggestedTeam', () {
      test('returns error for invalid roster ID', () async {
        final result = await dataService.submitSuggestedTeam(
          [],
          '',
          'user',
          'uid',
        );
        expect(result, 'Invalid roster ID.');
      });

      test('creates a new suggestion', () async {
        await fakeFirestore.collection('weekly_rosters').doc('roster1').set({
          'date': Timestamp.now(),
          'present_players': ['p1', 'p2'],
          'number_of_teams': 2,
        });
        await dataService.fetchLatestRoster();
        final teams = [
          [p1],
          [p2],
        ];
        final result = await dataService.submitSuggestedTeam(
          teams,
          'roster1',
          'test_user',
          'user_id',
        );
        expect(result, isNull);
        final query = await fakeFirestore.collection('suggested_teams').get();
        expect(query.docs.length, 1);
        final suggestion = SuggestedTeam.fromFirestore(query.docs.first);
        expect(suggestion.submittedBy, 'test_user');
        expect(suggestion.upvotes, 1);
        expect(suggestion.votedBy['user_id'], 'up');
      });
    });

    group('deletePlayer', () {
      test('deletes a player successfully', () async {
        final result = await dataService.deletePlayer('p1');
        expect(result, isNull);
        final doc = await fakeFirestore.collection('players').doc('p1').get();
        expect(doc.exists, isFalse);
        expect(dataService.players.any((p) => p.id == 'p1'), isFalse);
      });

      test('removes player from the latest roster if present', () async {
        await fakeFirestore.collection('weekly_rosters').add({
          'date': Timestamp.now(),
          'present_players': ['p1', 'p2'],
          'number_of_teams': 2,
        });
        await dataService.fetchLatestRoster();
        expect(dataService.latestRoster!.playerIds, contains('p1'));

        final result = await dataService.deletePlayer('p1');
        expect(result, isNull);

        final rosterDoc = await fakeFirestore
            .collection('weekly_rosters')
            .doc(dataService.latestRoster!.id)
            .get();
        final rosterData = rosterDoc.data();
        expect(rosterData!['present_players'], isNot(contains('p1')));
        expect(dataService.latestRoster!.playerIds, isNot(contains('p1')));
      });

      test('handles empty player ID', () async {
        final result = await dataService.deletePlayer('');
        expect(result, 'Player ID cannot be empty.');
      });

      test('handles Firestore errors gracefully', () async {
        final erroringFirestore = ErroringFakeFirebaseFirestore();
        dataService = DataService.test(erroringFirestore);
        final result = await dataService.deletePlayer('p1');
        expect(result, isNotNull);
      });
    });
  });

  group('DataService Coverage', () {
    late DataService dataService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataService = DataService.test(fakeFirestore);
    });

    test('DataService default constructor does not throw', () {
      expect(() => DataService(), returnsNormally);
    });

    test('fetchPlayers handles errors and sets loading state', () async {
      final erroringFirestore = ErroringFakeFirebaseFirestore();
      dataService = DataService.test(erroringFirestore);
      final List<bool> loadingStates = [];
      dataService.addListener(
        () => loadingStates.add(dataService.isLoadingPlayers),
      );
      await dataService.fetchPlayers();
      expect(loadingStates, [true, false]);
      expect(dataService.players, isEmpty);
    });

    test('fetchLatestRoster handles errors and sets loading state', () async {
      final erroringFirestore = ErroringFakeFirebaseFirestore();
      dataService = DataService.test(erroringFirestore);
      final List<bool> loadingStates = [];
      dataService.addListener(
        () => loadingStates.add(dataService.isLoadingRoster),
      );
      await dataService.fetchLatestRoster();
      expect(loadingStates, [true, false]);
      expect(dataService.latestRoster?.date, 'Error fetching roster');
    });

    test('fetchSuggestedTeams handles errors and sets loading state', () async {
      final erroringFirestore = ErroringFakeFirebaseFirestore();
      dataService = DataService.test(erroringFirestore);
      dataService.setLatestRosterForTest(
        WeeklyRoster(
          id: 'roster1',
          date: '',
          playerNames: [],
          playerIds: [],
          numberOfTeams: 2,
        ),
      );
      final List<bool> loadingStates = [];
      dataService.addListener(
        () => loadingStates.add(dataService.isLoadingSuggestedTeams),
      );
      await dataService.fetchSuggestedTeams();
      expect(loadingStates, [true, false]);
      expect(dataService.suggestedTeams, isEmpty);
    });

    test('addPlayer handles errors gracefully', () async {
      final erroringFirestore = ErroringFakeFirebaseFirestore();
      dataService = DataService.test(erroringFirestore);
      final result = await dataService.addPlayer('test');
      expect(result, isNotNull);
    });

    test('submitRoster handles errors gracefully', () async {
      final erroringFirestore = ErroringFakeFirebaseFirestore();
      dataService = DataService.test(erroringFirestore);
      final result = await dataService.submitRoster(['p1'], 2);
      expect(result, isNotNull);
    });

    test('submitSuggestedTeam handles errors gracefully', () async {
      final erroringFirestore = ErroringFakeFirebaseFirestore();
      dataService = DataService.test(erroringFirestore);
      final result = await dataService.submitSuggestedTeam(
        [],
        'roster1',
        'user1',
        'uid1',
      );
      expect(result, isNotNull);
    });

    test(
      'submitSuggestedTeam with duplicate that user already upvoted does not re-upvote',
      () async {
        final roster = await fakeFirestore.collection('weekly_rosters').add({
          'date': Timestamp.now(),
          'present_players': ['p1', 'p2'],
          'number_of_teams': 1,
        });
        final teams = [
          [Player(id: 'p1', name: 'Player 1')],
          [Player(id: 'p2', name: 'Player 2')],
        ];
        await dataService.fetchLatestRoster();
        await dataService.submitSuggestedTeam(
          teams,
          roster.id,
          'user1',
          'uid1',
        );
        final result = await dataService.submitSuggestedTeam(
          teams,
          roster.id,
          'user1',
          'uid1',
        );
        expect(result, 'DUPLICATE');
        final suggestion =
            (await fakeFirestore.collection('suggested_teams').get())
                .docs
                .first;
        expect(suggestion.data()['upvotes'], 1);
      },
    );
    test(
      'submitSuggestedTeam upvotes a duplicate suggestion if the user hasn\'t upvoted it',
      () async {
        final roster = await fakeFirestore.collection('weekly_rosters').add({
          'date': Timestamp.now(),
          'present_players': ['p1', 'p2'],
          'number_of_teams': 1,
        });

        final teams = [
          [Player(id: 'p1', name: 'Player 1')],
          [Player(id: 'p2', name: 'Player 2')],
        ];

        await dataService.fetchLatestRoster();

        // User 1 submits a team
        await dataService.submitSuggestedTeam(
          teams,
          roster.id,
          'user1',
          'uid1',
        );

        // User 2 submits the same team
        final result = await dataService.submitSuggestedTeam(
          teams,
          roster.id,
          'user2',
          'uid2',
        );

        // Expect it to be a duplicate and upvoted
        expect(result, 'DUPLICATE');
        final suggestionDoc = (await fakeFirestore.collection('suggested_teams').get()).docs.first;
        final suggestion = SuggestedTeam.fromFirestore(suggestionDoc);

        expect(suggestion.upvotes, 2);
        expect(suggestion.votedBy['uid1'], 'up');
        expect(suggestion.votedBy['uid2'], 'up');
      },
    );
  });
}

// --- Helper Classes for Mocking ---

class ErroringFakeFirebaseFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    throw FirebaseException(
      plugin: 'fake_firestore',
      message: 'An error occurred',
    );
  }
}

// A generic Mock class to avoid needing a specific mocking package.
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockFirebasePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp();
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseApp();
  }

  @override
  List<FirebaseAppPlatform> get apps => [MockFirebaseApp()];

  Future<void> checkName(String name) {
    return Future.value();
  }
}

class MockFirebaseApp extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseAppPlatform {
  @override
  String get name => 'mockapp';

  @override
  FirebaseOptions get options => const FirebaseOptions(
    apiKey: 'mock',
    appId: 'mock',
    messagingSenderId: 'mock',
    projectId: 'mock',
  );

  @override
  Future<void> delete() async {}

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}
