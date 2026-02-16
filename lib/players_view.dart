import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_service.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  final Set<String> _selectedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataService>(context, listen: false).fetchPlayers();
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
    // Capture the page's context, which has the ScaffoldMessenger.
    final pageContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use a StatefulBuilder to manage the dialog's internal state (for the loading indicator).
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
                  // Disable the button while loading to prevent multiple submissions.
                  onPressed: isLoading ? null : () async {
                    setState(() {
                      isLoading = true;
                    });

                    final dataService = Provider.of<DataService>(pageContext, listen: false);
                    final playerName = nameController.text;
                    final error = await dataService.addPlayer(playerName);

                    // Ensure the widget is still mounted before interacting with the UI.
                    if (!mounted) return;

                    // Pop the dialog using its own context.
                    Navigator.of(dialogContext).pop();

                    // Show the SnackBar using the page's context.
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
        setState(() {
          _selectedPlayerIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly roster submitted successfully!')),
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
          if (dataService.isLoadingPlayers) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => dataService.fetchPlayers(),
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
