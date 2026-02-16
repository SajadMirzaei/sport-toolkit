import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
}

class WeeklyRoster {
  final String id;
  final String date;
  final List<String> playerNames;
  final List<String> playerIds;
  final int numberOfTeams; // New field for the number of teams

  WeeklyRoster({required this.id, required this.date, required this.playerNames, required this.playerIds, required this.numberOfTeams});
}

// --- Data Service ---

class DataService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Player> _players = [];
  WeeklyRoster? _latestRoster;
  bool _isLoadingPlayers = false;
  bool _isLoadingRoster = false;

  List<Player> get players => _players;
  WeeklyRoster? get latestRoster => _latestRoster;
  bool get isLoadingPlayers => _isLoadingPlayers;
  bool get isLoadingRoster => _isLoadingRoster;

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
        'number_of_teams': numberOfTeams, // Save to Firestore
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
        // Default to 2 teams if no roster exists
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
      }
    } catch (e) {
      debugPrint('Error fetching latest roster: $e');
      _latestRoster = WeeklyRoster(id: '', date: 'Error fetching roster', playerNames: [], playerIds: [], numberOfTeams: 2);
    } finally {
      _isLoadingRoster = false;
      notifyListeners();
    }
  }

  Future<String?> submitSuggestedTeam(List<List<String>> teams, String rosterId, String username) async {
    try {
      // Convert the list of lists to a map of lists to avoid nested arrays
      final Map<String, List<String>> teamsMap = {};
      for (int i = 0; i < teams.length; i++) {
        teamsMap['team_$i'] = teams[i];
      }

      await _firestore.collection('suggested_teams').add({
        'teams': teamsMap,
        'rosterId': _firestore.collection('weekly_rosters').doc(rosterId),
        'submittedBy': username,
      });
      return null; // Success
    } catch (e) {
      debugPrint('Error submitting suggested team: $e');
      return e.toString(); // Failure
    }
  }

  // --- Existing Methods for Ratings Feature (HTTP) ---

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