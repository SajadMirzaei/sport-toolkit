
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/login_provider.dart';
import 'example_main.dart';
import 'view_rating.dart';
import 'login_page.dart';
import 'teams_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LoginProvider _loginProvider;

  @override
  void initState() {
    super.initState();
    _loginProvider = LoginProvider();
    _loginProvider.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginProvider>.value(
      value: _loginProvider,
      child: MaterialApp(
        title: 'Bay Area Futsal',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 28, 121, 226),
          ),
          useMaterial3: true,
        ),
        home: const _LoginChecker(),
        routes: {
          '/example': (context) => const ExamplePage(),
          '/ratings': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}

class _LoginChecker extends StatelessWidget {
  const _LoginChecker();

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final user = loginProvider.user;

    if (user != null) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bay Area Futsal'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ratings'),
              Tab(text: 'Teams'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/example');
              },
              child: const Text('Example', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                final loginProvider = Provider.of<LoginProvider>(context, listen: false);
                if (loginProvider.user != null) {
                  loginProvider.logout();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                } else {
                  Navigator.pushNamed(context, '/login');
                }
              },
              child: Consumer<LoginProvider>(
                builder: (context, loginProvider, child) {
                  return Text(
                    loginProvider.user != null ? 'Logout' : 'Login',
                    style: const TextStyle(color: Colors.black),
                  );
                },
              ),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            ViewRating(title: 'Player Ratings'),
            TeamsPage(),
          ],
        ),
      ),
    );
  }
}
