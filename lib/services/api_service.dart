import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
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
