import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_service.dart';

class TeamVotingView extends StatefulWidget {
  const TeamVotingView({super.key});

  @override
  State<TeamVotingView> createState() => _TeamVotingViewState();
}

class _TeamVotingViewState extends State<TeamVotingView> {
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
          if (dataService.isLoadingSuggestedTeams) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dataService.suggestedTeams.isEmpty) {
            return const Center(
              child: Text(
                'No suggested teams available for the latest roster.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: dataService.suggestedTeams.length,
            itemBuilder: (context, index) {
              final suggestedTeam = dataService.suggestedTeams[index];
              final cardColor = index.isEven ? Colors.amber.shade50 : Colors.amber.shade100;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade300, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildTeamViews(suggestedTeam.teams),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Suggested by: ${suggestedTeam.submittedBy}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up_alt_outlined),
                                onPressed: () {
                                  // TODO: Implement upvote functionality
                                },
                              ),
                              Text(
                                '${suggestedTeam.upvotes}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildTeamViews(List<List<Player>> teams) {
    List<Widget> teamWidgets = [];
    for (int i = 0; i < teams.length; i++) {
      teamWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team ${i + 1}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: teams[i].map((player) => Chip(label: Text(player.name))).toList(),
              ),
            ],
          ),
        ),
      );
    }
    return teamWidgets;
  }
}
