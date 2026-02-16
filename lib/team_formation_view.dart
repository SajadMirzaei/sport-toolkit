
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_service.dart';
import 'providers/login_provider.dart';

class TeamFormationPage extends StatefulWidget {
  const TeamFormationPage({super.key});

  @override
  State<TeamFormationPage> createState() => _TeamFormationPageState();
}

class _TeamFormationPageState extends State<TeamFormationPage> {
  List<Player> _unassignedPlayers = [];
  late List<List<Player>> _teams;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTeamsAndPlayers();
    });
  }

  void _initializeTeamsAndPlayers() {
    final dataService = Provider.of<DataService>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    dataService.fetchPlayers().then((_) {
      dataService.fetchLatestRoster().then((_) {
        if (mounted) {
          final roster = dataService.latestRoster;
          if (roster != null && roster.playerIds.isNotEmpty) {
            final allPlayers = Map.fromIterables(
                dataService.players.map((p) => p.id), dataService.players);

            final rosterPlayers = roster.playerIds
                .map((id) => allPlayers[id])
                .where((p) => p != null)
                .cast<Player>()
                .toList();
                
            setState(() {
              _unassignedPlayers = List.from(rosterPlayers);
              _teams = List.generate(roster.numberOfTeams, (_) => []);
              _isLoading = false;
            });
          } else {
            setState(() {
              _unassignedPlayers = [];
              _teams = List.generate(2, (_) => []); // Default to 2 teams if no roster
              _isLoading = false;
            });
          }
        }
      });
    });
  }

  void _submitTeams() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final rosterId = dataService.latestRoster?.id;
    final username = loginProvider.user?.displayName ?? 'Anonymous';
    final userId = loginProvider.user?.uid;

    if (rosterId == null || rosterId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find a roster to link the suggestion to.')),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit a suggestion.')),
      );
      return;
    }

    if (_unassignedPlayers.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All players must be assigned to a team before submitting.')),
      );
      return;
    }

    final teamSizes = _teams.map((team) => team.length).toList();
    if (teamSizes.isNotEmpty) {
      final min = teamSizes.reduce((a, b) => a < b ? a : b);
      final max = teamSizes.reduce((a, b) => a > b ? a : b);
      if (max - min > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teams are not balanced. Player counts per team cannot differ by more than one.')),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Suggestion'),
        content: const Text('Are you sure you want to submit these team suggestions?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Submit')),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await dataService.submitSuggestedTeam(_teams, rosterId, username, userId);

      if (mounted) {
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team suggestion submitted successfully! Your vote has been counted.')),
          );
           _initializeTeamsAndPlayers(); // Reset the page
           DefaultTabController.of(context)?.animateTo(1); // Switch to voting tab
        } else if (result == 'DUPLICATE') {
          await showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Suggestion Already Exists'),
                content: const Text(
                    'This team combination has already been suggested. Your submission has been counted as an upvote.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              );
            },
          );
          if (mounted) {
            DefaultTabController.of(context)?.animateTo(1);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit suggestion: $result')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        _initializeTeamsAndPlayers();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildUnassignedPlayersBox(),
          ),
          const SliverToBoxAdapter(
            child: Divider(height: 20, thickness: 2),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildTeamBox(index);
              },
              childCount: _teams.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: ElevatedButton(
                onPressed: _submitTeams,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                child: const Text('Submit Team Suggestion'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedPlayersBox() {
    return DragTarget<Player>(
      onWillAccept: (player) => true,
      onAccept: (player) {
        setState(() {
          for (var team in _teams) {
            team.removeWhere((p) => p.id == player.id);
          }
          if (!_unassignedPlayers.any((p) => p.id == player.id)) {
            _unassignedPlayers.add(player);
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
            color: candidateData.isNotEmpty ? Colors.lightBlue.withOpacity(0.3) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unassigned Players', style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              _buildPlayerList(_unassignedPlayers, 'unassigned'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamBox(int teamIndex) {
    return DragTarget<Player>(
      onWillAccept: (player) => true,
      onAccept: (player) {
        setState(() {
          _unassignedPlayers.removeWhere((p) => p.id == player.id);
          for (var team in _teams) {
            team.removeWhere((p) => p.id == player.id);
          }
          _teams[teamIndex].add(player);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
            color: candidateData.isNotEmpty ? Colors.lightGreen.withOpacity(0.3) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team ${teamIndex + 1}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              _buildPlayerList(_teams[teamIndex], 'team_$teamIndex'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerList(List<Player> players, String origin) {
    if (players.isEmpty) {
      final message = origin == 'unassigned' ? 'All players have been assigned!' : 'Drag players here';
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16.0),
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: players.map((player) {
          return Draggable<Player>(
            data: player,
            feedback: Material(
              elevation: 4.0,
              child: Chip(label: Text(player.name)),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: Chip(label: Text(player.name)),
            ),
            child: Chip(label: Text(player.name)),
          );
        }).toList(),
      ),
    );
  }
}
