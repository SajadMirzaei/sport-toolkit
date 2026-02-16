import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_service.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  Set<String> _selectedPlayerIds = {};
  bool _isInitialized = false; // Flag to prevent re-initialization

  @override
  void initState() {
    super.initState();
    // Schedule the data fetch for after the first frame is built.
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;
            return AlertDialog(
              title: const Text('Add New Player'),
              content: TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Player Name'),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
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
    final error = await dataService.submitRoster(_selectedPlayerIds.toList());

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
          
          if (dataService.isLoadingPlayers || (dataService.isLoadingRoster && dataService.latestRoster == null)) {
            return const Center(child: CircularProgressIndicator());
          }

          // Safely initialize the state after the build is complete.
          if (!_isInitialized && dataService.latestRoster != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedPlayerIds = dataService.latestRoster!.playerIds.toSet();
                  _isInitialized = true;
                });
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              // When refreshing, reset the flag and fetch new data.
              setState(() {
                _isInitialized = false;
              });
              await dataService.fetchPlayers();
              await dataService.fetchLatestRoster();
            },
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlayerDialog,
        tooltip: 'Add Player',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _selectedPlayerIds.isNotEmpty ? _submitRoster : null,
          child: const Text('Submit Roster for the Week'),
        ),
      ),
    );
  }
}
