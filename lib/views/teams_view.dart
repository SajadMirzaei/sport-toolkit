import 'package:flutter/material.dart';

import 'team_formation_view.dart'; // The drag-and-drop view
import 'team_voting_view.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget _buildTab(String text, IconData icon) {
      return Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      );
    }

    // By using a Column with a TabBar and an Expanded TabBarView,
    // we avoid a nested Scaffold, which was causing the layout overflow.
    return DefaultTabController(
      length: 2, // Two tabs: Create and Vote
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TabBar(
              tabs: [
                _buildTab('Suggest Teams', Icons.group_add),
                _buildTab('Vote Teams', Icons.how_to_vote),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                const TeamFormationPage(),      // The drag-and-drop page
                const TeamVotingView(),   // The new suggested teams view
              ],
            ),
          ),
        ],
      ),
    );
  }
}
