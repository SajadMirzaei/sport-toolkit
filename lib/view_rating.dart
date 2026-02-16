import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/login_provider.dart';
import 'table_component.dart';
import 'add_player_dialog.dart';
import 'data_service.dart';

class ViewRating extends StatefulWidget {
  const ViewRating({super.key, required this.title});

  final String title;

  @override
  State<ViewRating> createState() => ViewRatingState();
}

class ViewRatingState extends State<ViewRating> {
  List<Map<String, dynamic>> data = [];
  String orderBy = 'Player';
  bool ascending = true;
  bool isLoading = true;
  final DataService _dataService = DataService();
  final GlobalKey<AddPlayerDialogState> _dialogKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });
    data = await _dataService.fetchData();
    setState(() {
      isLoading = false;
    });
  }

  void _handleOpenDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddPlayerDialog(
          key: _dialogKey,
          onAddPlayer: () async {
            await _handleAddPlayer(_dialogKey.currentState!.getNewPlayer());
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _handleAddPlayer(Map<String, dynamic> newPlayer) async {
    try {
      await _dataService.handleAddPlayer(newPlayer);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add player')));
    }
  }

  void _handleSort(String property, bool ascending) {
    setState(() {
      orderBy = property;
      this.ascending = ascending;
    });
  }

  List<Map<String, dynamic>> get sortedData {
    if (isLoading) {
      return [];
    }

    List<Map<String, dynamic>> sortedList = List.from(data);
    sortedList.sort((a, b) {
      dynamic valueA = a[orderBy];
      dynamic valueB = b[orderBy];

      if (valueA == null && valueB == null) return 0;
      if (valueA == null) return ascending ? 1 : -1;
      if (valueB == null) return ascending ? -1 : 1;

      if (valueA is String) valueA = valueA.toLowerCase();
      if (valueB is String) valueB = valueB.toLowerCase();

      try {
        if (valueA is Comparable && valueB is Comparable) {
          return ascending
              ? valueA.compareTo(valueB)
              : valueB.compareTo(valueA);
        } else {
          if (valueA < valueB) {
            return ascending ? -1 : 1;
          }
          if (valueA > valueB) {
            return ascending ? 1 : -1;
          }
          return 0;
        }
      } catch (e) {
        print("Error comparing $valueA and $valueB: $e");
        return 0;
      }
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TableComponent(
                data: sortedData,
                orderBy: orderBy,
                ascending: ascending,
                onSort: _handleSort,
              ),
              if (loginProvider.isAdmin)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton(
                    onPressed: _handleOpenDialog,
                    child: const Icon(Icons.add),
                  ),
                )
            ],
          ));
  }
}
