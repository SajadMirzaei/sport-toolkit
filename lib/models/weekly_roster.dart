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
