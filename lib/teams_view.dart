import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_service.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataService>(context, listen: false).fetchLatestRoster();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DataService>(
        builder: (context, dataService, child) {
          final roster = dataService.latestRoster;

          return Scaffold(
            appBar: AppBar(
              title: Text('Weekly Roster (${roster?.date ?? ''})'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => dataService.fetchLatestRoster(),
                  tooltip: 'Refresh Roster',
                ),
              ],
            ),
            body: dataService.isLoadingRoster
                ? const Center(child: CircularProgressIndicator())
                : (roster == null || roster.playerNames.isEmpty)
                    ? const Center(
                        child: Text(
                          'No players in the latest roster.\nAdmin needs to submit one.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: roster.playerNames.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(roster.playerNames[index]),
                          );
                        },
                      ),
          );
        },
      ),
    );
  }
}
