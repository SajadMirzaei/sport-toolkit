import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/login_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Future<void> _handleEmailPasswordLogin() async {
    if (_formKey.currentState!.validate()) {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      try {
        await loginProvider.loginWithEmailAndPassword(_email, _password);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/ratings', (route) => false);
        }
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
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/ratings', (route) => false);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        child: Center(child: _buildForm()),
      ),
    );
  }
}
