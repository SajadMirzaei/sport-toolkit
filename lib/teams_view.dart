import 'package:flutter/material.dart';

import 'team_formation_view.dart'; // The drag-and-drop view

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // By using a Column with a TabBar and an Expanded TabBarView,
    // we avoid a nested Scaffold, which was causing the layout overflow.
    return DefaultTabController(
      length: 2, // Two tabs: Create and Vote
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Suggest Teams', icon: Icon(Icons.group_add)),
              Tab(text: 'Vote Teams', icon: Icon(Icons.how_to_vote)),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TeamFormationPage(),      // The drag-and-drop page
                VoteTeamsPlaceholder(),   // The placeholder for voting
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A placeholder widget for the future "Vote Teams" feature.
class VoteTeamsPlaceholder extends StatelessWidget {
  const VoteTeamsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'The UI for suggesting and voting on teams will be built here.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
