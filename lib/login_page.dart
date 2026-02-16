import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/login_provider.dart';
// import 'sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  // Future<void> _handleGoogleSignIn() async {
  //   final loginProvider = Provider.of<LoginProvider>(context, listen: false);
  //   try {
  //     await loginProvider.googleLogin();
  //   } catch (e) {
  //     _showErrorSnackBar(e.toString().replaceAll("Exception:", ""));
  //   }
  // }

  Future<void> _handleSignOut() async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    try {
      await loginProvider.logout();
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll("Exception:", ""));
    }
  }

  Future<void> _handleEmailPasswordLogin() async {
    if (_formKey.currentState!.validate()) {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      try {
        await loginProvider.loginWithEmailAndPassword(_email, _password);
      } catch (e) {
        _showErrorSnackBar(e.toString().replaceAll("Exception:", ""));
      }
    }
  }

  Future<void> _handleEmailPasswordSignUp() async {
    if (_formKey.currentState!.validate()) {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      try {
        await loginProvider.signUp(_email, _password);
      } catch (e) {
        _showErrorSnackBar(e.toString().replaceAll("Exception:", ""));
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildForm() {
    return SizedBox(
      width: 300.0,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              //controller: _emailController,
              onChanged: (value) {
                _email = value;
              },
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            TextFormField(
              //controller: _passwordController,
              onChanged: (value) {
                _password = value;
              },
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _handleEmailPasswordLogin,
                  child: const Text('Sign In'),
                ),
                ElevatedButton(
                  onPressed: _handleEmailPasswordSignUp,
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(User? user) {
    if (user != null) {
      return _buildLoggedInContent(user);
    } else {
      return _buildLoggedOutContent();
    }
  }

  Widget _buildLoggedOutContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildForm(),
          // buildSignInButton(onPressed: _handleGoogleSignIn),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent(User user) {
    if (user.providerData.any(
      (element) => element.providerId == 'google.com',
    )) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              // leading: GoogleUserCircleAvatar(identity: user),
              title: Text(user.displayName ?? ''),
              subtitle: Text(user.email ?? ''),
            ),
            ElevatedButton(
              onPressed: _handleSignOut,
              child: const Text('SIGN OUT'),
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildGenericUserInfo(user),
        ElevatedButton(
          onPressed: _handleSignOut,
          child: const Text('SIGN OUT'),
        ),
      ],
    );
  }

  Widget _buildGenericUserInfo(User user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const ListTile(title: Text("Welcome")),
          ListTile(title: Text(user.email ?? '')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final user = loginProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        child: Center(child: _buildMainContent(user)),
      ),
    );
  }
}
