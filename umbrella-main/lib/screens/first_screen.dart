import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/provider/user_provider.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  FirstScreenState createState() => FirstScreenState();
}

class FirstScreenState extends State<FirstScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _animationFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // 적절한 애니메이션 시간 설정
    );

    // ✅ 애니메이션 시작 + 로그인 상태 체크
    _controller.forward().whenComplete(() async {
      setState(() {
        _animationFinished = true;
      });

      // 로그인 상태 확인
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserFromStorage(); // SharedPreferences에서 토큰 불러오기

      if (!mounted) return;

      if (userProvider.isLoggedIn) {
        context.go('/main'); // ✅ 로그인 되어 있으면 main으로 이동
      }
      // ❌ 로그인 안 되어있으면 아무 것도 하지 않음 → 로그인/회원가입 버튼 보임
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26539C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 160),
              child: _animationFinished
                  ? Image.asset('lib/assets/anim_last_frame.jpg')
                  : Image.asset('lib/assets/anim.gif', gaplessPlayback: true),
            ),
            if (_animationFinished) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    shadowColor: Colors.black,
                    backgroundColor: const Color(0xff0088ff),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text(
                    "회원가입",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/login');
                },
                child: const Text(
                  "로그인",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ],
        ),
      ),
    );
  }
}
