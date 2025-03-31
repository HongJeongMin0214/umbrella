import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/first_screen.dart';
import 'screens/signup_1_screen.dart';
import 'screens/signup_2_screen.dart';
import 'screens/signup_3_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const FirstScreen()),
      GoRoute(
          path: '/signup', builder: (context, state) => const Signup1Screen()),
      GoRoute(
        path: '/signup2',
        builder: (context, state) {
          final email = state.extra as String;
          return Signup2Screen(email: email);
        },
      ),
      GoRoute(
          path: '/signup3', builder: (context, state) => const Signup3Screen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
    ],
  );

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
