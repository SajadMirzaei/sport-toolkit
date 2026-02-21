import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  Set<String> _selectedPlayerIds = {};
  int _numberOfTeams = 2; // Default number of teams
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataService = Provider.of<DataService>(context, listen: false);
      dataService.fetchPlayers();
      dataService.fetchLatestRoster();
    });
  }

  void _onPlayerSelected(String playerId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedPlayerIds.add(playerId);
      } else {
        _selectedPlayerIds.remove(playerId);
      }
    });
  }

  void _showAddPlayerDialog() {
    final nameController = TextEditingController();
    final pageContext = context;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Player'),
              content: TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });

                          final dataService = Provider.of<DataService>(pageContext, listen: false);
                          final playerName = nameController.text;
                          final error = await dataService.addPlayer(playerName);

                          if (!mounted) return;

                          Navigator.of(dialogContext).pop();

                          if (error == null) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(content: Text('Player "$playerName" added.')),
                            );
                          } else {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(content: Text('Failed to add player: $error')),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitRoster() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    final error = await dataService.submitRoster(_selectedPlayerIds.toList(), _numberOfTeams);

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly roster has been updated!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DataService>(
        builder: (context, dataService, child) {
          if (dataService.isLoadingPlayers || (dataService.isLoadingRoster && !_isInitialized)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_isInitialized && dataService.latestRoster != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedPlayerIds = dataService.latestRoster!.playerIds.toSet();
                  _numberOfTeams = dataService.latestRoster!.numberOfTeams;
                  _isInitialized = true;
                });
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isInitialized = false;
              });
              await dataService.fetchPlayers();
              await dataService.fetchLatestRoster();
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Number of Teams:', style: TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (_numberOfTeams > 2) {
                                  setState(() {
                                    _numberOfTeams--;
                                  });
                                }
                              },
                            ),
                            Text('$_numberOfTeams', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  _numberOfTeams++;
                                });
                              },
                            ),
                          ],
                        ),
                        const VerticalDivider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Selected Players:', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 12),
                            Chip(
                              label: Text(
                                '${_selectedPlayerIds.length}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: dataService.players.length,
                    itemBuilder: (context, index) {
                      final player = dataService.players[index];
                      final isSelected = _selectedPlayerIds.contains(player.id);

                      return CheckboxListTile(
                        title: Text(player.name),
                        value: isSelected,
                        onChanged: (bool? value) {
                          _onPlayerSelected(player.id, value);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlayerDialog,
        tooltip: 'Add Player',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedPlayerIds.isNotEmpty ? _submitRoster : null,
            child: const Text('Submit Roster for the Week'),
          ),
        ),
      ),
    );
  }
}
