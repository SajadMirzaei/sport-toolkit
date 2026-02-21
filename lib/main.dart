
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 28, 121, 226),
    );

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
                useMaterial3: true,
                colorScheme: colorScheme,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: colorScheme.surface.withAlpha(150),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                   prefixIconColor: colorScheme.onSurfaceVariant,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
                 dialogTheme: DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    )
                  )
                ),
                tabBarTheme: TabBarThemeData(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.primary,
                  ),
                  labelColor: colorScheme.onPrimary,
                  unselectedLabelColor: colorScheme.onSurface,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                ),
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
            bottom: TabBar(
              tabs: tabs,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                child: Text(loginProvider.user != null ? 'Logout' : 'Login'),
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
