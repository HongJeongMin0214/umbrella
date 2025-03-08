import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Signup3Screen extends StatefulWidget {
  const Signup3Screen({super.key});

  @override
  _Signup3ScreenState createState() => _Signup3ScreenState();
}

class _Signup3ScreenState extends State<Signup3Screen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isNameFilled = false;
  bool _isIdFilled = false;
  bool _isPasswordFilled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        _isNameFilled = _nameController.text.isNotEmpty;
      });
    });
    _idController.addListener(() {
      setState(() {
        _isIdFilled = _idController.text.isNotEmpty;
      });
    });
    _passwordController.addListener(() {
      setState(() {
        _isPasswordFilled = _passwordController.text.isNotEmpty;
      });
    });
  }

  void _validateAndProceed() {
    if (!_isNameFilled || !_isIdFilled || !_isPasswordFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("모든 항목을 입력해주세요."),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      context.go('/login'); // ✅ 회원가입 완료 후 로그인 화면으로 이동
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 기본 뒤로 가기 방지
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/'); // ✅ 첫 화면으로 이동
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              context.go('/'); // ✅ AppBar 뒤로 가기 버튼 클릭 시 first_screen 이동
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
              _buildTextField("아이디", _idController),
              const SizedBox(height: 25),
              _buildTextField("비밀번호", _passwordController, isPassword: true),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
        ),
      ),
    );
  }
}
