import 'package:cloud_firestore/cloud_firestore.dart';

import 'player.dart';

class SuggestedTeam {
  final String id;
  final List<List<Player>> teams;
  final String submittedBy;
  final int upvotes;
  final int downvotes;
  final Map<String, String> votedBy;
  final String? teamHash;

  SuggestedTeam({
    required this.id,
    required this.teams,
    required this.submittedBy,
    this.upvotes = 0,
    this.downvotes = 0,
    this.votedBy = const {},
    this.teamHash,
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
      downvotes: data['downvotes'] ?? 0,
      votedBy: Map<String, String>.from(data['votedBy'] ?? {}),
      teamHash: data['teamHash'],
    );
  }
}
