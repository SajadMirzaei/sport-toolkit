import 'package:flutter/material.dart';

import 'team_formation_view.dart'; // The drag-and-drop view
import 'team_voting_view.dart';

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
