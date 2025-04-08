import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/first_screen.dart';
import 'screens/signup_1_screen.dart';
import 'screens/signup_2_screen.dart';
import 'screens/signup_3_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/provider/user_provider.dart';
import 'package:umbrella/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  await userProvider.loadUserFromStorage();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userProvider),
        Provider<ApiService>(create: (_) => ApiService()), // ✅ 여기에 DI 등록
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const FirstScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final isPasswordReset = state.extra as bool? ??
              false; // <수정> extra 값을 가져와서 사용. state.extra가 bool 타입이면 그대로 사용. null이면 false.
          return SignupOrResetScreen(isPasswordReset: isPasswordReset);
        },
      ),
      GoRoute(
        path: '/signup2',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email = extra['email'] as String? ?? '';
          final isPasswordReset = extra['isPasswordReset'] as bool? ?? false;
          return Signup2Screen(email: email, isPasswordReset: isPasswordReset);
        },
      ),
      GoRoute(
        path: '/signup3',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email = extra['email'] as String? ?? '';
          final isPasswordReset = extra['isPasswordReset'] as bool? ?? false;
          return Signup3Screen(email: email, isPasswordReset: isPasswordReset);
        },
      ),
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
