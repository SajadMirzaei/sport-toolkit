import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/login_provider.dart';
import '../services/data_service.dart';
import '../models/models.dart';

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
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final userId = loginProvider.user?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Consumer<DataService>(
        builder: (context, dataService, child) {
          if (dataService.isLoadingSuggestedTeams) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dataService.suggestedTeams.isEmpty) {
            return Center(
              child: Text(
                'No suggested teams available for the latest roster.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
            );
          }

          return ListView.builder(
            itemCount: dataService.suggestedTeams.length,
            itemBuilder: (context, index) {
              final suggestedTeam = dataService.suggestedTeams[index];
              final cardColor = index.isEven ? colorScheme.surface : colorScheme.surfaceVariant;
              final userVote = userId != null ? suggestedTeam.votedBy[userId] : null;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outline, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildTeamViews(suggestedTeam.teams, theme),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Suggested by: ${suggestedTeam.submittedBy}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  userVote == 'up' ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                                  color: userVote == 'up' ? colorScheme.primary : colorScheme.onSurface,
                                ),
                                onPressed: () {
                                  if (userId != null) {
                                    dataService.vote(suggestedTeam, userId, 'up');
                                  }
                                },
                              ),
                              Text(
                                '${suggestedTeam.upvotes - suggestedTeam.downvotes}',
                                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(
                                  userVote == 'down' ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                                  color: userVote == 'down' ? colorScheme.primary : colorScheme.onSurface,
                                ),
                                onPressed: () {
                                  if (userId != null) {
                                    dataService.vote(suggestedTeam, userId, 'down');
                                  }
                                },
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

  List<Widget> _buildTeamViews(List<List<Player>> teams, ThemeData theme) {
    List<Widget> teamWidgets = [];
    for (int i = 0; i < teams.length; i++) {
      teamWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team ${i + 1}',
                style: theme.textTheme.titleLarge,
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
      if (i < teams.length - 1) {
        teamWidgets.add(const Divider());
      }
    }
    return teamWidgets;
  }
}
