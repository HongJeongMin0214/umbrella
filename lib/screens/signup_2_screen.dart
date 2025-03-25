// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'dart:async';
// import 'package:umbrella/services/api_service.dart';
// import 'dart:developer' as developer;

// class Signup2Screen extends StatefulWidget {
//   final String email;
//   const Signup2Screen({super.key, required this.email});

//   @override
//   _Signup2ScreenState createState() => _Signup2ScreenState();
// }

// class _Signup2ScreenState extends State<Signup2Screen> {
//   final TextEditingController _codeController = TextEditingController();
//   int _remainingSeconds = 60;
//   Timer? _timer;
//   bool _isTimeOver = false;
//   final RegExp _codeRegex = RegExp(r'^\d{6}$'); // 6자리 숫자 정규식
//   final ApiService _apiService = ApiService();

//   @override
//   void initState() {
//     super.initState();
//     _startCountdown();
//   }

//   void _startCountdown() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_remainingSeconds > 0) {
//         setState(() {
//           _remainingSeconds--;
//         });
//       } else {
//         setState(() {
//           _isTimeOver = true;
//         });
//         timer.cancel();
//       }
//     });
//   }

//   void _resendCode() async {
//     setState(() {
//       _remainingSeconds = 60;
//       _isTimeOver = false;
//     });
//     _startCountdown(); // 타이머 재시작

//     // 서버로 인증번호 재전송 요청 보내기
//     bool sent = await _apiService.sendVerificationCode(widget.email);

//     // 인증번호 재발송 성공/실패 처리
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(sent ? "새 인증번호가 전송되었습니다." : "인증번호 전송 실패."),
//     ));
//   }

//   Future<void> _validateCode() async {
//     String email = widget.email; // `Signup1Screen`에서 넘겨받은 이메일

//     if (_codeRegex.hasMatch(_codeController.text.trim())) {
//       // 서버로 이메일과 인증번호를 보내 인증 여부 확인
//       bool isValid =
//           await _apiService.verifyCode(email, _codeController.text.trim());

//       if (!mounted) return; // 위젯이 사라졌다면 실행하지 않음

//       if (isValid) {
//         // 인증 성공 후 `signup3` 화면으로 이동
//         context.pushNamed('/signup3');
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("인증번호를 확인해주세요."),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("인증번호는 6자리 숫자여야 합니다."),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _codeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new),
//           onPressed: () {
//             context.go('/signup');
//           },
//         ),
//         title: const Text(
//           "회원가입",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: false,
//         backgroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(30),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: 50,
//               child: TextField(
//                 controller: _codeController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   hintText: "인증번호",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(7),
//                     borderSide:
//                         const BorderSide(color: Colors.orange, width: 2),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(7),
//                     borderSide:
//                         const BorderSide(color: Colors.orange, width: 2),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             _isTimeOver
//                 ? Align(
//                     alignment: Alignment.centerLeft,
//                     child: TextButton(
//                       onPressed: _resendCode,
//                       child: const Text(
//                         "인증번호 재발송",
//                         style: TextStyle(color: Colors.blue, fontSize: 14),
//                       ),
//                     ),
//                   )
//                 : RichText(
//                     text: TextSpan(
//                       style: const TextStyle(color: Colors.grey, fontSize: 14),
//                       children: [
//                         const TextSpan(text: "메일로 전송된 인증번호를 입력해 주세요.\n"),
//                         const TextSpan(
//                             text: "제한 시간이 지나면 다시 요청해야 합니다. (남은 시간: "),
//                         TextSpan(
//                           text: _formatTime(_remainingSeconds),
//                           style: const TextStyle(
//                               color: Colors.red, fontWeight: FontWeight.bold),
//                         ),
//                         const TextSpan(text: ")"),
//                       ],
//                     ),
//                   ),
//             const SizedBox(height: 10),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _validateCode,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(7),
//                   ),
//                 ),
//                 child: const Text(
//                   "확인",
//                   style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatTime(int seconds) {
//     int minutes = seconds ~/ 60;
//     int secs = seconds % 60;
//     return "$minutes:${secs.toString().padLeft(2, '0')}";
//   }
// }
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:umbrella/services/api_service.dart';

class Signup2Screen extends StatefulWidget {
  final String email;
  const Signup2Screen({super.key, required this.email});

  @override
  _Signup2ScreenState createState() => _Signup2ScreenState();
}

class _Signup2ScreenState extends State<Signup2Screen> {
  final TextEditingController _codeController = TextEditingController();
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _isTimeOver = false;
  final RegExp _codeRegex = RegExp(r'^\d{6}$'); // 6자리 숫자 정규식
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  // 타이머 시작
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _isTimeOver = true;
        });
        timer.cancel();
      }
    });
  }

  // 인증번호 재발송 함수
  void _resendCode() async {
    setState(() {
      _remainingSeconds = 60;
      _isTimeOver = false;
    });
    _startCountdown(); // 타이머 재시작

    // 서버로 인증번호 재전송 요청 보내기
    bool sent = await _apiService.sendVerificationCode(widget.email);
    if (!mounted) return;

    // 인증번호 재발송 성공/실패 처리
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent ? "새 인증번호가 전송되었습니다." : "인증번호 전송 실패."),
    ));
  }

  // 인증번호 검증 함수
  Future<void> _validateCode() async {
    String email = widget.email; // `Signup1Screen`에서 넘겨받은 이메일

    if (_codeRegex.hasMatch(_codeController.text.trim())) {
      // 서버로 이메일과 인증번호를 보내 인증 여부 확인
      bool isValid =
          await _apiService.verifyCode(email, _codeController.text.trim());

      if (!mounted) return; // 위젯이 사라졌다면 실행하지 않음

      if (isValid) {
        if (!mounted) return;
        context.push('/signup3');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("인증번호를 확인해주세요."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("인증번호는 6자리 숫자여야 합니다."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            context.go('/signup');
          },
        ),
        title: const Text(
          "회원가입",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 50,
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "인증번호",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _isTimeOver
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _resendCode,
                      child: const Text(
                        "인증번호 재발송",
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      children: [
                        const TextSpan(text: "메일로 전송된 인증번호를 입력해 주세요.\n"),
                        const TextSpan(
                            text: "제한 시간이 지나면 다시 요청해야 합니다. (남은 시간: "),
                        TextSpan(
                          text: _formatTime(_remainingSeconds),
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ")"),
                      ],
                    ),
                  ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _validateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  "확인",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }
}
