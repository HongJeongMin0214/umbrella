import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:umbrella/services/api_service.dart';

class Signup3Screen extends StatefulWidget {
  const Signup3Screen({super.key});

  @override
  _Signup3ScreenState createState() => _Signup3ScreenState();
}

class _Signup3ScreenState extends State<Signup3Screen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  String _errorMessage = ''; // 오류 메시지 변수

  @override
  void initState() {
    super.initState();
  }

  // 입력값에 대한 유효성 검사 및 오류 메시지 처리
  void _validateAndProceed() {
    String name = _nameController.text.trim();
    String id = _idController.text.trim();
    String password = _passwordController.text.trim();
    String passwordConfirm = _passwordConfirmController.text.trim();

    if (!_isNameValid(name)) {
      setState(() {
        _errorMessage = "이름을 정확히 입력해 주세요 (숫자 포함 안됨)";
      });
    } else if (!_isIdValid(id)) {
      setState(() {
        _errorMessage = "아이디는 8자리 숫자여야 합니다.";
      });
    } else if (!_isPasswordValid(password)) {
      setState(() {
        _errorMessage = "비밀번호는 7자 이상이고, 특수문자가 포함되어야 합니다.";
      });
    } else if (!_isPasswordConfirmValid(password, passwordConfirm)) {
      setState(() {
        _errorMessage = "비밀번호 확인이 일치하지 않습니다.";
      });
    } else {
      _registerUser(name, id, password); // 유효성 검사 통과 후 서버로 회원가입 요청
    }
  }

  // 이름 유효성 체크 (숫자 포함하면 안됨)
  bool _isNameValid(String name) {
    return !RegExp(r'\d').hasMatch(name);
  }

  // 학번 유효성 체크 (8자 숫자만 가능)
  bool _isIdValid(String id) {
    return RegExp(r'^\d{8}$').hasMatch(id);
  }

  // 비밀번호 유효성 체크 (7자 이상, 특수문자 포함)
  bool _isPasswordValid(String password) {
    return RegExp(r'^(?=.*[!@#$%^&*])[A-Za-z\d@$!%*?&]{7,}$')
        .hasMatch(password);
  }

  // 비밀번호 확인 유효성 체크 (비밀번호와 동일한지)
  bool _isPasswordConfirmValid(String password, String passwordConfirm) {
    return password == passwordConfirm;
  }

  // 회원가입 요청을 서버로 보내는 함수
  void _registerUser(String name, String id, String password) async {
    bool success = await ApiService().registerUser(name, id, password);
    if (!mounted) return;

    if (success) {
      // 회원가입 성공 후 로그인 화면으로 이동
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("회원가입 성공!"),
        backgroundColor: Colors.green,
      ));
      context.push('/login'); // 로그인 화면으로 이동
    } else {
      // 회원가입 실패 처리
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("회원가입 실패. 다시 시도해주세요."),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
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
            context.go('/signup2'); // 첫 화면으로 이동
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
            _buildTextField("이름", _nameController),
            const SizedBox(height: 25),
            _buildTextField("아이디(8자리 학번)", _idController),
            const SizedBox(height: 25),
            _buildTextField("비밀번호", _passwordController, isPassword: true),
            const SizedBox(height: 25),
            _buildTextField("비밀번호 확인", _passwordConfirmController,
                isPassword: true),
            const SizedBox(height: 25),
            // 오류 메시지 표시
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _validateAndProceed,
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

  Widget _buildTextField(String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
        ),
      ),
    );
  }
}
