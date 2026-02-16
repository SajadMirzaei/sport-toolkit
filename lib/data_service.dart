import 'package:http/http.dart' as http;
import 'dart:convert';

class DataService {
  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      print('Fetching data from Cloud Function...');
      final Uri uri = Uri.parse(
        'https://read-all-ratings-vnrobchonq-uc.a.run.app',
      );
      print("URI: $uri");
      final response = await http.get(uri);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP error! Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      final result = json.decode(response.body);
      print('Decoded data: $result');

      if (result != null) {
        final List<Map<String, dynamic>> newData =
            result.entries.map<Map<String, dynamic>>((entry) {
              Map<String, dynamic> playerData = {
                'Player': entry.key,
                'Pace': '-',
                'Shooting': '-',
                'Passing': '-',
                'Dribbling': '-',
                'Defending': '-',
                'Physical': '-',
                'GoalKeeping': '-',
              };

              // Fill in the data if it exists
              Map<String, dynamic>.from(entry.value).forEach((key, value) {
                playerData[key] = value;
              });

              return playerData;
            }).toList();
        return newData;
      } else {
        print('No data returned from the Cloud Function');
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

      if (response.statusCode == 200) {
        print('Player added successfully');
      } else {
        print('Error adding player: ${response.reasonPhrase}');
        throw Exception("Could not add player");
      }
    } catch (error) {
      print('Error adding player: $error');
      throw Exception("Could not add player");
    }
  }
}
