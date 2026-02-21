
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'providers/login_provider.dart';
import 'services/data_service.dart';
import 'views/view_rating.dart';
import 'views/login_page.dart';
import 'views/teams_view.dart';
import 'views/players_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<FirebaseApp> _initFirebase() async {
    if (Firebase.apps.isEmpty) {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return Firebase.app();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LoginProvider(FirebaseAuth.instance)),
              ChangeNotifierProvider(create: (_) => DataService()),
            ],
            child: MaterialApp(
              title: 'Bay Area Futsal',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color.fromARGB(255, 28, 121, 226),
                ),
                useMaterial3: true,
              ),
              home: const LoginChecker(),
              routes: {
                '/ratings': (context) => const HomePage(),
                '/login': (context) => const LoginPage(),
              },
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class LoginChecker extends StatelessWidget {
  const LoginChecker();

  @override
  Widget build(BuildContext context) {
    // Initialize providers
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    loginProvider.getCurrentUser();

    return Consumer<LoginProvider>(
      builder: (context, loginProvider, child) {
        if (loginProvider.user != null) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginProvider>(builder: (context, loginProvider, child) {
      final bool isAdmin = loginProvider.isAdmin;
      final int tabLength = isAdmin ? 3 : 2;

      final List<Widget> tabs = [
        const Tab(text: 'Ratings'),
        const Tab(text: 'Teams'),
      ];
      if (isAdmin) {
        tabs.add(const Tab(text: 'Players'));
      }

      final List<Widget> tabViews = [
        const ViewRating(title: 'Player Ratings'),
        const TeamsPage(),
      ];
      if (isAdmin) {
        tabViews.add(const PlayersPage());
      }
      return DefaultTabController(
        length: tabLength,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Bay Area Futsal'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(
              tabs: tabs,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (loginProvider.user != null) {
                    loginProvider.logout();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  } else {
                    Navigator.pushNamed(context, '/login');
                  }
                },
                child: Text(
                  loginProvider.user != null ? 'Logout' : 'Login',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          body: TabBarView(
            children: tabViews,
          ),
        ),
      );
    });
  }
}
