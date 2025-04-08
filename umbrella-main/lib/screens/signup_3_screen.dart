import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:umbrella/services/api_service.dart';

class Signup3Screen extends StatefulWidget {
  final bool isPasswordReset;
  final String email;

  const Signup3Screen({
    super.key,
    required this.email,
    required this.isPasswordReset,
  });

  @override
  _Signup3ScreenState createState() => _Signup3ScreenState();
}

class _Signup3ScreenState extends State<Signup3Screen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  String _errorMessage = '';

  void _validateAndProceed() {
    String password = _passwordController.text.trim();
    String passwordConfirm = _passwordConfirmController.text.trim();
    String name = _nameController.text.trim();
    String id = _idController.text.trim();

    if (!widget.isPasswordReset) {
      if (name.isEmpty) {
        setState(() {
          _errorMessage = "이름을 입력해주세요.";
        });
        return;
      }

      if (!RegExp(r'^[가-힣a-zA-Z]+$').hasMatch(name)) {
        setState(() {
          _errorMessage = "이름에는 한글 또는 영문자만 입력할 수 있습니다.";
        });
        return;
      }

      if (!RegExp(r'^\d{8}$').hasMatch(id)) {
        setState(() {
          _errorMessage = "아이디는 8자리 숫자여야 합니다.";
        });
        return;
      }
    }
    if (!_isPasswordValid(password)) {
      setState(() {
        _errorMessage = "비밀번호는 7자 이상이고, 특수문자가 포함되어야 합니다.";
      });
    } else if (!_isPasswordConfirmValid(password, passwordConfirm)) {
      setState(() {
        _errorMessage = "비밀번호 확인이 일치하지 않습니다.";
      });
    } else {
      if (widget.isPasswordReset) {
        _changePassword(widget.email, _idController.text.trim(), password);
      } else {
        _registerUser(_nameController.text.trim(), _idController.text.trim(),
            password, widget.email);
      }
    }
  }

  bool _isPasswordValid(String password) {
    return RegExp(r'^(?=.*[!@#$%^&*])[A-Za-z\d@$!%*?&]{7,}$')
        .hasMatch(password);
  }

  bool _isPasswordConfirmValid(String password, String passwordConfirm) {
    return password == passwordConfirm;
  }

  void _changePassword(
      String email, String currentPassword, String newPassword) async {
    bool success =
        await ApiService().changePw(email, currentPassword, newPassword);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("비밀번호 변경 성공!"),
          backgroundColor: Colors.green,
        ));
      context.push('/login');
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("비밀번호 변경 실패. 다시 시도해주세요."),
          backgroundColor: Colors.red,
        ));
    }
  }

  void _registerUser(
      String name, String id, String password, String email) async {
    bool success = await ApiService().registerUser(name, id, password, email);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("회원가입 성공!"),
          backgroundColor: Colors.green,
        ));
      context.push('/login');
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("회원가입 실패. 다시 시도해주세요."),
          backgroundColor: Colors.red,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isPasswordReset ? "비밀번호 변경" : "회원가입",
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            if (!widget.isPasswordReset) ...[
              _buildTextField("이름", _nameController),
              const SizedBox(height: 25),
              _buildTextField(
                "아이디(8자리 학번)",
                _idController,
                isPassword: widget.isPasswordReset,
              ),
              const SizedBox(height: 25),
            ],
            _buildTextField("새 비밀번호", _passwordController, isPassword: true),
            const SizedBox(height: 25),
            _buildTextField("비밀번호 확인", _passwordConfirmController,
                isPassword: true),
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
                child: Text(
                  widget.isPasswordReset ? "변경하기" : "가입하기",
                  style: const TextStyle(
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
