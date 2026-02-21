import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/login_provider.dart';

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
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            onChanged: (value) {
              _email = value;
            },
            decoration: InputDecoration(
              labelText: 'Email',              
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            onChanged: (value) {
              _password = value;
            },
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleEmailPasswordLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text("Don't have an account?"),
              TextButton(
                onPressed: _handleEmailPasswordSignUp,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    kLoginPageTitle,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    kLoginPageSubtitle,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildForm()
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}