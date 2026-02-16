import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddPlayerDialog extends StatefulWidget {
  final VoidCallback onAddPlayer;

  const AddPlayerDialog({super.key, required this.onAddPlayer});

  @override
  AddPlayerDialogState createState() => AddPlayerDialogState();
}

class AddPlayerDialogState extends State<AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _paceController = TextEditingController();
  final TextEditingController _shootingController = TextEditingController();
  final TextEditingController _passingController = TextEditingController();
  final TextEditingController _dribblingController = TextEditingController();
  final TextEditingController _defendingController = TextEditingController();
  final TextEditingController _physicalController = TextEditingController();
  final TextEditingController _goalKeepingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Player'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _paceController,
                decoration: InputDecoration(labelText: 'Pace'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pace';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0 || double.parse(value) > 10) {
                    return 'Pace must be between 0 and 10';
                  }
                  return null;
                },
              ),
              // Similar TextFormFields for other numerical fields
              TextFormField(
                controller: _shootingController,
                decoration: InputDecoration(labelText: 'Shooting'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter shooting';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0 || double.parse(value) > 10) {
                    return 'Shooting must be between 0 and 10';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passingController,
                decoration: InputDecoration(labelText: 'Passing'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter passing';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0 || double.parse(value) > 10) {
                    return 'Passing must be between 0 and 10';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dribblingController,
                decoration: InputDecoration(labelText: 'Dribbling'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dribbling';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0 || double.parse(value) > 10) {
                    return 'Dribbling must be between 0 and 10';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _defendingController,
                decoration: InputDecoration(labelText: 'Defending'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter defending';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0 || double.parse(value) > 10) {
                    return 'Defending must be between 0 and 10';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _physicalController,
                decoration: InputDecoration(labelText: 'Physical'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter physical';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0 || double.parse(value) > 10) {
                    return 'Physical must be between 0 and 10';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _goalKeepingController,
                decoration: InputDecoration(labelText: 'GoalKeeping'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter goalKeeping';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0 || double.parse(value) > 10) {
                    return 'GoalKeeping must be between 0 and 10';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAddPlayer();
              Navigator.of(context).pop();
            }
          },
          child: Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _paceController.dispose();
    _shootingController.dispose();
    _passingController.dispose();
    _dribblingController.dispose();
    _defendingController.dispose();
    _physicalController.dispose();
    _goalKeepingController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getNewPlayer() {
    return {
      'Name': _nameController.text,
      'Pace': double.parse(_paceController.text),
      'Shooting': double.parse(_shootingController.text),
      'Passing': double.parse(_passingController.text),
      'Dribbling': double.parse(_dribblingController.text),
      'Defending': double.parse(_defendingController.text),
      'Physical': double.parse(_physicalController.text),
      'GoalKeeping': double.parse(_goalKeepingController.text),
    };
  }
}
