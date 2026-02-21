import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyRoster {
  final String id;
  final String date;
  final DateTime preciseDate;
  final List<String> playerNames;
  final List<String> playerIds;
  final int numberOfTeams;

  WeeklyRoster({
    required this.id,
    required this.date,
    required this.preciseDate,
    required this.playerNames,
    required this.playerIds,
    required this.numberOfTeams,
  });

  factory WeeklyRoster.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp rosterTimestamp = data['date'];
    final rosterDate = rosterTimestamp.toDate();
    final dateString = '${rosterDate.month}/${rosterDate.day}/${rosterDate.year}';

    return WeeklyRoster(
      id: doc.id,
      date: dateString,
      preciseDate: rosterDate,
      playerNames: [], // This will be populated later
      playerIds: List<String>.from(data['present_players'] ?? []),
      numberOfTeams: data.containsKey('number_of_teams') ? data['number_of_teams'] : 2,
    );
  }

  WeeklyRoster copyWith({
    String? id,
    String? date,
    DateTime? preciseDate,
    List<String>? playerNames,
    List<String>? playerIds,
    int? numberOfTeams,
  }) {
    return WeeklyRoster(
      id: id ?? this.id,
      date: date ?? this.date,
      preciseDate: preciseDate ?? this.preciseDate,
      playerNames: playerNames ?? this.playerNames,
      playerIds: playerIds ?? this.playerIds,
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
    );
  }
}
