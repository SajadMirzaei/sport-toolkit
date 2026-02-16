// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:myapp/sign_in_button.dart';

import 'dart:async';
import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

const List<String> scopes = <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly',
];

GoogleSignIn googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: 'your-client_id.apps.googleusercontent.com',
  scopes: scopes,
);

void main() {
  runApp(const MaterialApp(home: SignInDemo()));
}

class SignInDemo extends StatefulWidget {
  const SignInDemo({super.key});

  @override
  State createState() => _SignInDemoState();
}

class _SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount? _currentUser;
  String _contactText = '';

  @override
  void initState() {
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((
      GoogleSignInAccount? account,
    ) async {
      bool isAuthorized = account != null;
      if (kIsWeb && account != null) {
        isAuthorized = await googleSignIn.canAccessScopes(scopes);
      }

      setState(() {
        _currentUser = account;
      });

      if (isAuthorized && _currentUser != null) {
        _handleGetContact();
      }
    });
    googleSignIn.signInSilently();
  }

  Future<void> _handleGetContact() async {
    setState(() {
      _contactText = 'Loading contact info...';
    });
    final http = await _currentUser?.authHeaders;
    if (http != null) {
      final response = await http;
      if (response != null) {
        final Map<String, dynamic> data = response;
        final formatted = json.encode(data);
        setState(() {
          _contactText = 'response: $formatted';
        });
      } else {
        setState(() {
          _contactText = 'failed to retrieve contact info';
        });
      }
    } else {
      setState(() {
        _contactText = 'failed to get authentication headers';
      });
    }
  }

  Future<void> _pickFirstNamedContact() async {
    setState(() {
      _contactText = 'Loading contact info...';
    });
    final http = await _currentUser?.authHeaders;
    if (http != null) {
      final response = await http;
      if (response != null) {
        final Map<String, dynamic> data = response;
        final formatted = json.encode(data);
        setState(() {
          _contactText = 'response: $formatted';
        });
      } else {
        setState(() {
          _contactText = 'failed to retrieve contact info';
        });
      }
    } else {
      setState(() {
        _contactText = 'failed to get authentication headers';
      });
    }
  }

  Future<void> _handleSignIn() async {
    try {
      await googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleAuthorizeScopes() async {
    await googleSignIn.signIn();
  }

  Future<void> _handleSignOut() => googleSignIn.disconnect();

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    if (user != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(identity: user),
            title: Text(user.displayName ?? ''),
            subtitle: Text(user.email),
          ),
          const Text('Signed in successfully.'),
          Text('User Profile: $_contactText'),
          ElevatedButton(
            onPressed: _handleGetContact,
            child: const Text('REFRESH'),
          ),
          ElevatedButton(
            onPressed: _pickFirstNamedContact,
            child: const Text('PICK FIRST CONTACT'),
          ),
          ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('SIGN OUT'),
          ),
          ElevatedButton(
            onPressed: _handleAuthorizeScopes,
            child: const Text('Request Additional Scopes'),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text('You are not currently signed in.'),
          buildSignInButton(onPressed: _handleSignIn),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign In')),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: _buildBody(),
      ),
    );
  }
}
