import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _animationFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(microseconds: 5940000), // GIF 애니메이션 전체 재생 시간
    );

    // 애니메이션이 끝나면 상태를 변경하여 마지막 프레임을 보여줌
    _controller.forward().whenComplete(() {
      setState(() {
        _animationFinished = true; // 애니메이션 종료됨
      });
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
                  ? Image.asset(
                      'lib/assets/anim_last_frame.jpg') // 🎯 마지막 프레임 (81프레임)
                  : Image.asset('lib/assets/anim.gif',
                      gaplessPlayback: true), // GIF 애니메이션
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  context.go('/signup'); // 회원가입 페이지 이동
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
                context.go('/login'); // 로그인 페이지 이동
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
        ),
      ),
    );
  }
}
