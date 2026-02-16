import 'package:flutter/material.dart';
import 'providers/login_provider.dart';
import 'example_main.dart';
import 'view_rating.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
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
        home: _LoginChecker(),
        routes: {
          '/example': (context) => NavigationScaffold(page: ExamplePage()),
          '/ratings':
              (context) =>
                  NavigationScaffold(page: ViewRating(title: 'Player Ratings')),
          '/login': (context) => NavigationScaffold(page: LoginPage()),
          // Add more routes as needed'
        },
      ),
    );
  }
}

class _LoginChecker extends StatefulWidget {
  @override
  _LoginCheckerState createState() => _LoginCheckerState();
}

class _LoginCheckerState extends State<_LoginChecker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("_LoginCheckerState: build called");
    final loginProvider = Provider.of<LoginProvider>(context);
    final user = loginProvider.user;
    print("_LoginCheckerState: user: ${user?.displayName ?? 'null'}");

    if (user != null) {
      return NavigationScaffold(page: ViewRating(title: 'Player Ratings'));
    } else {
      return NavigationScaffold(page: LoginPage());
    }
  }
}

class NavigationScaffold extends StatelessWidget {
  final Widget page;

  const NavigationScaffold({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bay Area Futsal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/ratings');
            },
            child: const Text(
              'View Ratings',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/example');
            },
            child: const Text('Example', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: page,
    );
  }
}
