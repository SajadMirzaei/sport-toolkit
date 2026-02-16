import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// --- Data Models ---

class Player {
  final String id;
  final String name;

  Player({required this.id, required this.name});

  factory Player.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Player(
      id: doc.id,
      name: data['name'] ?? 'No Name',
    );
  }

  // Convert a Player instance to a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Create a Player instance from a Map
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class WeeklyRoster {
  final String id;
  final String date;
  final List<String> playerNames;
  final List<String> playerIds;
  final int numberOfTeams;

  WeeklyRoster({
    required this.id,
    required this.date,
    required this.playerNames,
    required this.playerIds,
    required this.numberOfTeams,
  });
}

class SuggestedTeam {
  final String id;
  final List<List<Player>> teams; // Changed to hold Player objects
  final String submittedBy;
  final int upvotes;

  SuggestedTeam({
    required this.id,
    required this.teams,
    required this.submittedBy,
    this.upvotes = 0,
  });

  factory SuggestedTeam.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> teamsMap = Map<String, dynamic>.from(data['teams'] ?? {});
    List<List<Player>> teams = [];
    
    var sortedKeys = teamsMap.keys.toList()..sort();
    
    for (var key in sortedKeys) {
      if (teamsMap[key] != null) {
        var playerList = List<Map<String, dynamic>>.from(teamsMap[key]);
        teams.add(playerList.map((playerMap) => Player.fromJson(playerMap)).toList());
      }
    }

    return SuggestedTeam(
      id: doc.id,
      teams: teams,
      submittedBy: data['submittedBy'] ?? 'Unknown',
      upvotes: data['upvotes'] ?? 0,
    );
  }
}

// --- Data Service ---

class DataService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Player> _players = [];
  WeeklyRoster? _latestRoster;
  List<SuggestedTeam> _suggestedTeams = [];
  bool _isLoadingPlayers = false;
  bool _isLoadingRoster = false;
  bool _isLoadingSuggestedTeams = false;

  List<Player> get players => _players;
  WeeklyRoster? get latestRoster => _latestRoster;
  List<SuggestedTeam> get suggestedTeams => _suggestedTeams;
  bool get isLoadingPlayers => _isLoadingPlayers;
  bool get isLoadingRoster => _isLoadingRoster;
  bool get isLoadingSuggestedTeams => _isLoadingSuggestedTeams;

  Future<void> fetchPlayers() async {
    _isLoadingPlayers = true;
    notifyListeners();
    try {
      final playersSnapshot = await _firestore.collection('players').orderBy('name').get();
      _players = playersSnapshot.docs.map((doc) => Player.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching players: $e');
    } finally {
      _isLoadingPlayers = false;
      notifyListeners();
    }
  }

  Future<String?> addPlayer(String name) async {
    if (name.trim().isEmpty) return null;
    try {
      await _firestore.collection('players').add({'name': name.trim()});
      fetchPlayers();
      return null;
    } catch (e) {
      debugPrint('Error adding player: $e');
      return e.toString();
    }
  }

  Future<String?> submitRoster(List<String> playerIds, int numberOfTeams) async {
    if (playerIds.isEmpty) return 'Please select at least one player.';

    try {
      final rosterData = {
        'date': Timestamp.now(),
        'present_players': playerIds,
        'number_of_teams': numberOfTeams,
      };

      if (_latestRoster != null && _latestRoster!.id.isNotEmpty) {
        await _firestore.collection('weekly_rosters').doc(_latestRoster!.id).update(rosterData);
      } else {
        await _firestore.collection('weekly_rosters').add(rosterData);
      }

      await fetchLatestRoster();
      return null;
    } catch (e) {
      debugPrint('Error submitting roster: $e');
      return e.toString();
    }
  }

  Future<void> fetchLatestRoster() async {
    _isLoadingRoster = true;
    notifyListeners();
    try {
      final rosterSnapshot = await _firestore.collection('weekly_rosters').orderBy('date', descending: true).limit(1).get();

      if (rosterSnapshot.docs.isEmpty) {
        _latestRoster = WeeklyRoster(id: '', date: 'No roster submitted yet', playerNames: [], playerIds: [], numberOfTeams: 2);
      } else {
        final latestRosterDoc = rosterSnapshot.docs.first;
        final docData = latestRosterDoc.data();
        final Timestamp rosterTimestamp = docData['date'];
        final rosterDate = rosterTimestamp.toDate();
        final dateString = '${rosterDate.month}/${rosterDate.day}/${rosterDate.year}';

        final List<String> playerIds = List<String>.from(docData['present_players']);
        final int numberOfTeams = docData.containsKey('number_of_teams') ? docData['number_of_teams'] : 2;
        List<String> playerNames = [];

        if (playerIds.isNotEmpty) {
           final playersSnapshot = await _firestore.collection('players').where(FieldPath.documentId, whereIn: playerIds).get();
           final Map<String, String> playerMap = { for (var doc in playersSnapshot.docs) doc.id : doc.data()['name'] };
           playerNames = playerIds.map((id) => playerMap[id] ?? 'Unknown Player').toList();
        }

        _latestRoster = WeeklyRoster(id: latestRosterDoc.id, date: dateString, playerNames: playerNames, playerIds: playerIds, numberOfTeams: numberOfTeams);
        await fetchSuggestedTeams();
      }
    } catch (e) {
      debugPrint('Error fetching latest roster: $e');
      _latestRoster = WeeklyRoster(id: '', date: 'Error fetching roster', playerNames: [], playerIds: [], numberOfTeams: 2);
    } finally {
      _isLoadingRoster = false;
      notifyListeners();
    }
  }

  Future<void> fetchSuggestedTeams() async {
    if (latestRoster == null || latestRoster!.id.isEmpty) {
      _suggestedTeams = [];
      notifyListeners();
      return;
    }

    _isLoadingSuggestedTeams = true;
    notifyListeners();

    try {
      final rosterRef = _firestore.collection('weekly_rosters').doc(latestRoster!.id);
      final snapshot = await _firestore
          .collection('suggested_teams')
          .where('rosterId', isEqualTo: rosterRef)
          .get();

      _suggestedTeams = snapshot.docs.map((doc) => SuggestedTeam.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching suggested teams: $e');
      _suggestedTeams = [];
    } finally {
      _isLoadingSuggestedTeams = false;
      notifyListeners();
    }
  }

  Future<String?> submitSuggestedTeam(List<List<Player>> teams, String rosterId, String username) async {
    if (rosterId.isEmpty) return 'Invalid roster ID.';
    
    try {
      final Map<String, List<Map<String, dynamic>>> teamsMap = {};
      for (int i = 0; i < teams.length; i++) {
        teamsMap['team_$i'] = teams[i].map((player) => player.toJson()).toList();
      }

      await _firestore.collection('suggested_teams').add({
        'teams': teamsMap,
        'rosterId': _firestore.collection('weekly_rosters').doc(rosterId),
        'submittedBy': username,
        'upvotes': 0,
      });
      
      await fetchSuggestedTeams(); 
      
      return null;
    } catch (e) {
      debugPrint('Error submitting suggested team: $e');
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      final Uri uri = Uri.parse(
        'https://read-all-ratings-vnrobchonq-uc.a.run.app',
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP error! Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      final result = json.decode(response.body);

      if (result != null) {
        final List<Map<String, dynamic>> newData =
            result.entries.map<Map<String, dynamic>>((entry) {
              Map<String, dynamic> playerData = {
                'Player': entry.key,
                'Pace': '-', 'Shooting': '-', 'Passing': '-', 'Dribbling': '-',
                'Defending': '-', 'Physical': '-', 'GoalKeeping': '-',
              };
              Map<String, dynamic>.from(entry.value).forEach((key, value) {
                playerData[key] = value;
              });
              return playerData;
            }).toList();
        return newData;
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching data: $error');
      return [];
    }
  }

  Future<void> handleAddPlayer(Map<String, dynamic> newPlayer) async {
    try {
      final response = await http.post(
        Uri.parse('https://add-player-ratings-vnrobchonq-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newPlayer),
      );

      if (response.statusCode != 200) {
        throw Exception("Could not add player: ${response.reasonPhrase}");
      }
    } catch (error) {
      throw Exception("Could not add player: $error");
    }
  }
}