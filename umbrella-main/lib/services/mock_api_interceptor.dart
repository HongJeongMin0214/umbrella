import 'dart:math';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;

class MockApiInterceptor extends Interceptor {
  static final Map<String, String> _codeStore = {}; // 인증번호 저장
  static final Map<String, Map<String, String>> _users = {}; // 사용자 정보 저장

  // 로그인 요청 처리
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 이메일 인증번호 전송 처리 (기존 코드)
    if (options.path == 'https://mock-api.com/send-email') {
      String email = options.data["email"];

      if (email == 'sch@sch.ac.kr') {
        handler.resolve(Response(requestOptions: options, statusCode: 300));
        return;
      }
      // 새로운 인증번호 생성 및 저장
      String code =
          (Random().nextInt(900000) + 100000).toString(); // 6자리 인증번호 생성
      _codeStore[email] = code;

      developer.log("📩 Mock 인증번호 발송: $code");
      developer.log("✅ 인증번호 저장 완료: $_codeStore");

      handler.resolve(Response(
          requestOptions: options, statusCode: 200)); // 서버 응답 시 200 상태 반환
    }

    // 회원가입 요청 처리 (기존 코드)
    else if (options.path == 'https://mock-api.com/register') {
      String? name = options.data["name"];
      String? id = options.data["id"];
      String? password = options.data["password"];

      if (name == null || name.isEmpty) {
        developer.log("❌ 이름이 비어 있음!");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "이름이 없습니다.",
        ));
        return;
      }

      if (id == null ||
          id.isEmpty ||
          id.length != 8 ||
          !RegExp(r'^\d{8}$').hasMatch(id)) {
        developer.log("❌ 아이디가 유효하지 않음!");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "아이디는 8자리 숫자여야 합니다.",
        ));
        return;
      }

      if (password == null ||
          password.isEmpty ||
          password.length < 7 ||
          !RegExp(r'[@$!%*?&]').hasMatch(password)) {
        developer.log("❌ 비밀번호가 유효하지 않음!");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "비밀번호는 7자 이상이고 특수문자가 포함되어야 합니다.",
        ));
        return;
      }

      // 아이디 중복 체크
      if (_users.containsKey(id)) {
        developer.log("❌ 이미 존재하는 아이디: $id");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "아이디가 이미 존재합니다.",
        ));
        return;
      }

      // 사용자 정보 저장
      _users[id] = {"name": name, "id": id, "password": password};

      developer.log("✅ Mock 회원가입 성공: ${_users[id]}");
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {"message": "회원가입 성공!"}, // 서버에서 성공 메시지 반환
      ));
    }

    // 로그인 요청 처리
    else if (options.path == 'https://mock-api.com/login') {
      String? id = options.data["id"];
      String? password = options.data["password"];

      if (id == null || id.isEmpty || password == null || password.isEmpty) {
        developer.log("❌ 아이디 또는 비밀번호가 비어 있음!");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "아이디 또는 비밀번호가 비어 있습니다.",
        ));
        return;
      }

      // 아이디 존재 여부 체크
      if (!_users.containsKey(id)) {
        developer.log("❌ 아이디가 존재하지 않음!");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "아이디가 존재하지 않습니다.",
        ));
        return;
      }

      // 비밀번호 일치 여부 체크
      if (_users[id]?["password"] != password) {
        developer.log("❌ 비밀번호가 틀림!");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "비밀번호가 틀립니다.",
        ));
        return;
      }

      // 로그인 성공 처리
      developer.log("✅ 로그인 성공: ${_users[id]}");
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {"message": "로그인 성공!"}, // 서버에서 로그인 성공 메시지 반환
      ));
    }

    // 인증번호 검증 요청 처리 (기존 코드)
    else if (options.path == 'https://mock-api.com/verify-code') {
      String? email = options.data["email"];
      String? enteredCode = options.data["code"]; // 'otp' 대신 'code'로 수정

      if (email == null ||
          email.isEmpty ||
          enteredCode == null ||
          enteredCode.isEmpty) {
        developer.log("❌ 검증 실패: 이메일 또는 인증번호가 비어 있음!");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "이메일 또는 인증번호 값이 없습니다.",
        ));
        return;
      }

      // 인증번호 검증
      if (_codeStore[email] == enteredCode) {
        developer.log("✅ 인증번호 검증 성공!");
        handler.resolve(Response(
            requestOptions: options, statusCode: 200)); // 성공 시 200 상태 코드 반환
      } else {
        developer.log("❌ 인증번호 검증 실패! 저장된 인증번호: ${_codeStore[email]}");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "인증번호가 올바르지 않습니다. 다시 입력해주세요.",
        ));
      }
    }

    // 그 외의 요청 처리
    else {
      handler.next(options);
    }
  }
}
