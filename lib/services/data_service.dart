import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

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

  String generateTeamHash(List<List<Player>> teams) {
    // 1. Sort players within each team by ID
    final sortedTeams = teams.map((team) {
      final sortedPlayers = List<Player>.from(team);
      sortedPlayers.sort((a, b) => a.id.compareTo(b.id));
      return sortedPlayers.map((p) => p.id).join(';');
    }).toList();

    // 2. Sort the teams themselves
    sortedTeams.sort();

    // 3. Join into a final hash string
    return sortedTeams.join('|');
  }

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
      _suggestedTeams.sort((a, b) => (b.upvotes - b.downvotes).compareTo(a.upvotes - a.downvotes));

    } catch (e) {
      debugPrint('Error fetching suggested teams: $e');
      _suggestedTeams = [];
    } finally {
      _isLoadingSuggestedTeams = false;
      notifyListeners();
    }
  }

  Future<void> vote(SuggestedTeam suggestion, String userId, String voteType) async {
    final suggestionRef = _firestore.collection('suggested_teams').doc(suggestion.id);
    
    await _firestore.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(suggestionRef);
      final freshSuggestion = SuggestedTeam.fromFirestore(freshSnapshot);

      final currentVote = freshSuggestion.votedBy[userId];
      int newUpvotes = freshSuggestion.upvotes;
      int newDownvotes = freshSuggestion.downvotes;
      final Map<String, String> newVotedBy = Map.from(freshSuggestion.votedBy);

      if (currentVote == voteType) { // User is retracting their vote
        if (voteType == 'up') newUpvotes--;
        else newDownvotes--;
        newVotedBy.remove(userId);
      } else { // User is changing vote or voting for the first time
        if (currentVote == 'up') newUpvotes--;
        else if (currentVote == 'down') newDownvotes--;
        
        if (voteType == 'up') newUpvotes++;
        else newDownvotes++;
        newVotedBy[userId] = voteType;
      }

      transaction.update(suggestionRef, {
        'upvotes': newUpvotes,
        'downvotes': newDownvotes,
        'votedBy': newVotedBy,
      });
    });

    await fetchSuggestedTeams();
  }

  Future<String?> submitSuggestedTeam(List<List<Player>> teams, String rosterId, String username, String userId) async {
    if (rosterId.isEmpty) return 'Invalid roster ID.';
    
    final teamHash = generateTeamHash(teams);
    final rosterRef = _firestore.collection('weekly_rosters').doc(rosterId);

    try {
      final querySnapshot = await _firestore
          .collection('suggested_teams')
          .where('rosterId', isEqualTo: rosterRef)
          .where('teamHash', isEqualTo: teamHash)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Duplicate found, upvote it instead
        final existingSuggestion = SuggestedTeam.fromFirestore(querySnapshot.docs.first);
        await vote(existingSuggestion, userId, 'up');
        return 'DUPLICATE'; 
      }

      // No duplicate, create a new suggestion
      final Map<String, List<Map<String, dynamic>>> teamsMap = {};
      for (int i = 0; i < teams.length; i++) {
        teamsMap['team_$i'] = teams[i].map((player) => player.toJson()).toList();
      }

      await _firestore.collection('suggested_teams').add({
        'teams': teamsMap,
        'rosterId': rosterRef,
        'submittedBy': username,
        'upvotes': 1, // Start with one upvote from the user who submitted it
        'downvotes': 0,
        'votedBy': {userId: 'up'}, // Record the submitter's upvote
        'teamHash': teamHash,
      });
      
      await fetchSuggestedTeams(); 
      
      return null;
    } catch (e) {
      debugPrint('Error submitting suggested team: $e');
      return e.toString();
    }
  }
}
