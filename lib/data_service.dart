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

  WeeklyRoster({required this.id, required this.date, required this.playerNames, required this.playerIds});
}

// --- Data Service ---

class DataService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- State for New Roster Feature ---
  List<Player> _players = [];
  WeeklyRoster? _latestRoster;
  bool _isLoadingPlayers = false;
  bool _isLoadingRoster = false;

  // --- Getters for New Roster Feature ---
  List<Player> get players => _players;
  WeeklyRoster? get latestRoster => _latestRoster;
  bool get isLoadingPlayers => _isLoadingPlayers;
  bool get isLoadingRoster => _isLoadingRoster;

  // --- Methods for New Roster Feature (Firestore) ---

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
      fetchPlayers(); // Refresh the list
      return null; // Success
    } catch (e) {
      debugPrint('Error adding player: $e');
      return e.toString(); // Return error message
    }
  }

  Future<String?> submitRoster(List<String> playerIds) async {
    if (playerIds.isEmpty) return 'Please select at least one player.';

    try {
      final rosterData = {
        'date': Timestamp.now(),
        'present_players': playerIds,
      };

      // If a roster was loaded and has a valid ID, update it. Otherwise, create a new one.
      if (_latestRoster != null && _latestRoster!.id.isNotEmpty) {
        await _firestore.collection('weekly_rosters').doc(_latestRoster!.id).update(rosterData);
      } else {
        await _firestore.collection('weekly_rosters').add(rosterData);
      }

      await fetchLatestRoster(); // Refresh the roster view with the updated data
      return null; // Success
    } catch (e) {
      debugPrint('Error submitting roster: $e');
      return e.toString(); // Return error message
    }
  }

  Future<void> fetchLatestRoster() async {
    _isLoadingRoster = true;
    notifyListeners();
    try {
      final rosterSnapshot = await _firestore.collection('weekly_rosters').orderBy('date', descending: true).limit(1).get();

      if (rosterSnapshot.docs.isEmpty) {
        _latestRoster = WeeklyRoster(id: '', date: 'No roster submitted yet', playerNames: [], playerIds: []);
      } else {
        final latestRosterDoc = rosterSnapshot.docs.first;
        final Timestamp rosterTimestamp = latestRosterDoc['date'];
        final rosterDate = rosterTimestamp.toDate();
        final dateString = '${rosterDate.month}/${rosterDate.day}/${rosterDate.year}';

        final List<String> playerIds = List<String>.from(latestRosterDoc['present_players']);
        List<String> playerNames = [];

        if (playerIds.isNotEmpty) {
           final playersSnapshot = await _firestore.collection('players').where(FieldPath.documentId, whereIn: playerIds).get();
           final Map<String, String> playerMap = { for (var doc in playersSnapshot.docs) doc.id : doc.data()['name'] };
           for (String playerId in playerIds) {
              playerNames.add(playerMap[playerId] ?? 'Unknown Player');
           }
        }
        _latestRoster = WeeklyRoster(id: latestRosterDoc.id, date: dateString, playerNames: playerNames, playerIds: playerIds);
      }
    } catch (e) {
      debugPrint('Error fetching latest roster: $e');
      _latestRoster = WeeklyRoster(id: '', date: 'Error fetching roster', playerNames: [], playerIds: []);
    } finally {
      _isLoadingRoster = false;
      notifyListeners();
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