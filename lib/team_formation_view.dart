
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_service.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Using a CustomScrollView makes the entire content area scrollable,
    // preventing any overflow errors.
    return RefreshIndicator(
      onRefresh: () async {
        _initializeTeamsAndPlayers();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Unassigned Players', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildPlayerList(_unassignedPlayers, 'unassigned'),
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
        ],
      ),
    );
  }

  Widget _buildTeamBox(int teamIndex) {
    return DragTarget<Player>(
      onWillAccept: (player) => true,
      onAccept: (player) {
        setState(() {
          // Ensure player is not in the unassigned list
          _unassignedPlayers.removeWhere((p) => p.id == player.id);
          // Remove from any other team before adding to the new one
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
