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

  // UserProvider 인스턴스를 생성하고, 앱 시작 시 사용자 데이터 로드
  final userProvider = UserProvider();
  await userProvider.loadUserFromStorage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) =>
                userProvider), // UserProvider를 ChangeNotifierProvider로 설정
        Provider<ApiService>(create: (_) => ApiService()), // ApiService DI 등록
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
          final isPasswordReset = state.extra as bool? ?? false;
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
