import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';

class MockApiInterceptor extends Interceptor {
  static final Map<String, String> _codeStore = {};
  static final Map<String, Map<String, String>> _users = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;

    if (path == '/send-email') {
      String email = options.data?["email"] ?? '';
      bool isPasswordReset =
          options.queryParameters['isPasswordReset'] == 'true';

      if (isPasswordReset) {
        bool emailExists = _users.values.any((user) => user["email"] == email);

        if (emailExists) {
          String code = (Random().nextInt(900000) + 100000).toString();
          _codeStore[email] = code;
          print("📩 Mock 인증번호 발송 (비밀번호 변경): $code");
          developer.log("📩 Mock 인증번호 발송 (비밀번호 변경): $code");
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        } else {
          developer.log("❌ 비밀번호 변경 실패 - 존재하지 않는 이메일: $email");
          handler.resolve(Response(
              requestOptions: options,
              statusCode: 404,
              data: {"message": "Email not found"}));
        }
      } else {
        bool emailExists = _users.values.any((user) => user["email"] == email);

        if (emailExists) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 404,
            data: {"message": "Email already exists"},
          ));
        } else {
          String code = (Random().nextInt(900000) + 100000).toString();
          _codeStore[email] = code;
          print("📩 Mock 인증번호 발송: $code");
          developer.log("📩 Mock 인증번호 발송: $code");
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        }
      }
    } else if (path == '/verify-code') {
      String? email = options.data?["email"];
      String? code = options.data?["code"];

      if (_codeStore[email] == code) {
        developer.log("✅ 인증번호 검증 성공!");
        handler.resolve(Response(requestOptions: options, statusCode: 200));
      } else {
        developer.log("❌ 인증번호 검증 실패! 저장된 인증번호: ${_codeStore[email]}");
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "인증번호가 올바르지 않습니다.",
        ));
      }
    } else if (path == '/register') {
      String? name = options.data?["name"];
      String? id = options.data?["id"];
      String? password = options.data?["password"];
      String? email = options.data?["email"];

      if (name == null || name.isEmpty) {
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
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "비밀번호는 7자 이상이고 특수문자가 포함되어야 합니다.",
        ));
        return;
      }

      if (_users.containsKey(id)) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "아이디가 이미 존재합니다.",
        ));
        return;
      }

      _users[id] = {
        "email": email!,
        "name": name,
        "id": id,
        "password": password
      };
      developer.log("✅ Mock 회원가입 성공: ${_users[id]}");
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {"message": "회원가입 성공!"},
      ));
    } else if (path == '/login') {
      String? id = options.data?["id"];
      String? password = options.data?["password"];

      if (!_users.containsKey(id)) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "아이디가 존재하지 않습니다.",
        ));
        return;
      }

      if (_users[id]?["password"] != password) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "비밀번호가 틀립니다.",
        ));
        return;
      }

      final payload = {
        "id": _users[id]!["id"],
        "name": _users[id]!["name"],
        "email": _users[id]!["email"],
        "exp": DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch ~/
            1000,
      };
      final header =
          base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
      final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
      final mockToken = "$header.$encodedPayload.mock-signature";

      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {"message": "로그인 성공!", "token": mockToken},
      ));
    } else if (path == '/profile') {
      final authHeader = options.headers['Authorization'];
      developer.log("🔐 Authorization header: $authHeader");

      if (authHeader == null || !authHeader.toString().startsWith('Bearer ')) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "Authorization header missing or invalid",
        ));
        return;
      }

      final token = authHeader.toString().substring(7);
      final payload = _decodeJwtPayload(token);
      final userId = payload['id'];

      if (!_users.containsKey(userId)) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "사용자 정보 없음",
        ));
        return;
      }

      final user = _users[userId]!;

      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          "id": user["id"],
          "name": user["name"],
          "email": user["email"],
        },
      ));
    } else if (path == '/changePw') {
      String email = options.data?["email"] ?? '';
      String newPassword = options.data?["newPassword"] ?? '';

      final userEntry = _users.entries.firstWhere(
        (entry) => entry.value["email"] == email,
        orElse: () => const MapEntry('', {}),
      );

      if (userEntry.key.isEmpty) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "해당 이메일의 유저가 없습니다.",
        ));
        return;
      }

      _users[userEntry.key]?["password"] = newPassword;

      developer.log("✅ 비밀번호 변경 성공 (mock)");
      handler.resolve(Response(requestOptions: options, statusCode: 200));
    }

    // ✅ 우산함 상태 응답 처리
    else if (options.path == '/umbrella-status') {
      final boxId = options.queryParameters['id'];

      if (boxId == '1') {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              "umbrella": 5,
              "emptySlot": 3,
            },
          ),
        );
      } else if (boxId == '2') {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              "umbrella": 0,
              "emptySlot": 8,
            },
          ),
        );
      } else {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 404,
            data: {
              "message": "해당 우산함을 찾을 수 없습니다.",
            },
          ),
        );
      }
    } else if (path == '/use-umbrella') {
      final userId = options.data?['userId'];
      final lockerId = options.data?['lockerId'];

      developer.log("📡 [MOCK] 우산 사용 요청 - 사용자: $userId, 우산함: $lockerId");

      if (userId == null || lockerId == null) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: "userId 또는 lockerId 누락",
        ));
        return;
      }

      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {"message": "우산 사용 기록 완료"},
      ));
    } else {
      handler.next(options);
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    try {
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(payload);
    } catch (e) {
      developer.log("❌ JWT 디코딩 실패: $e");
      return {};
    }
  }
}

// import 'dart:math';
// import 'package:dio/dio.dart';
// import 'dart:developer' as developer;

// class MockApiInterceptor extends Interceptor {
//   static final Map<String, String> _codeStore = {}; // 인증번호 저장
//   static final Map<String, Map<String, String>> _users = {}; // 사용자 정보 저장

//   // 로그인 요청 처리
//   @override
//   void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
//     // 이메일 인증번호 전송 처리 (기존 코드)
//     if (options.path == 'https://mock-api.com/send-email') {
//       String email = options.data["email"];

//       // 비밀번호 변경 요청인지 여부를 확인하는 로직
//       bool isPasswordReset =
//           options.queryParameters['isPasswordReset'] == 'true';

//       if (isPasswordReset) {
//         // 비밀번호 변경 시에는 이미 존재하는 이메일에 대해 인증번호를 발송
//         if (email == 'sch@sch.ac.kr') {
//           String code = (Random().nextInt(900000) + 100000).toString();
//           _codeStore[email] = code;

//           developer.log("📩 Mock 인증번호 발송 (비밀번호 변경): $code");
//           handler.resolve(Response(requestOptions: options, statusCode: 200));
//         } else {
//           // 🔹 등록된 이메일이 아니면 인증번호 전송 실패
//           developer.log("❌ 비밀번호 변경 실패 - 존재하지 않는 이메일: $email");
//           handler.resolve(Response(requestOptions: options, statusCode: 404));
//         }
//       } else {
//         // 🔹 일반 회원가입 로직
//         if (email == 'sch@sch.ac.kr') {
//           handler.resolve(Response(
//               requestOptions: options, statusCode: 300)); // 이미 존재하는 이메일
//         } else {
//           // 새로운 이메일일 경우 인증번호 전송
//           String code = (Random().nextInt(900000) + 100000).toString();
//           _codeStore[email] = code;

//           developer.log("📩 Mock 인증번호 발송: $code");
//           handler.resolve(Response(requestOptions: options, statusCode: 200));
//         }
//       }
//     }
//     // 회원가입 요청 처리 (기존 코드)
//     else if (options.path == 'https://mock-api.com/register') {
//       String? name = options.data["name"];
//       String? id = options.data["id"];
//       String? password = options.data["password"];

//       if (name == null || name.isEmpty) {
//         developer.log("❌ 이름이 비어 있음!");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "이름이 없습니다.",
//         ));
//         return;
//       }

//       if (id == null ||
//           id.isEmpty ||
//           id.length != 8 ||
//           !RegExp(r'^\d{8}$').hasMatch(id)) {
//         developer.log("❌ 아이디가 유효하지 않음!");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "아이디는 8자리 숫자여야 합니다.",
//         ));
//         return;
//       }

//       if (password == null ||
//           password.isEmpty ||
//           password.length < 7 ||
//           !RegExp(r'[@$!%*?&]').hasMatch(password)) {
//         developer.log("❌ 비밀번호가 유효하지 않음!");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "비밀번호는 7자 이상이고 특수문자가 포함되어야 합니다.",
//         ));
//         return;
//       }

//       // 아이디 중복 체크
//       if (_users.containsKey(id)) {
//         developer.log("❌ 이미 존재하는 아이디: $id");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "아이디가 이미 존재합니다.",
//         ));
//         return;
//       }

//       // 사용자 정보 저장
//       _users[id] = {"name": name, "id": id, "password": password};

//       developer.log("✅ Mock 회원가입 성공: ${_users[id]}");
//       handler.resolve(Response(
//         requestOptions: options,
//         statusCode: 200,
//         data: {"message": "회원가입 성공!"}, // 서버에서 성공 메시지 반환
//       ));
//     }

//     // 로그인 요청 처리
//     else if (options.path == 'https://mock-api.com/login') {
//       String? id = options.data["id"];
//       String? password = options.data["password"];

//       if (id == null || id.isEmpty || password == null || password.isEmpty) {
//         developer.log("❌ 아이디 또는 비밀번호가 비어 있음!");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "아이디 또는 비밀번호가 비어 있습니다.",
//         ));
//         return;
//       }

//       // 아이디 존재 여부 체크
//       if (!_users.containsKey(id)) {
//         developer.log("❌ 아이디가 존재하지 않음!");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "아이디가 존재하지 않습니다.",
//         ));
//         return;
//       }

//       // 비밀번호 일치 여부 체크
//       if (_users[id]?["password"] != password) {
//         developer.log("❌ 비밀번호가 틀림!");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "비밀번호가 틀립니다.",
//         ));
//         return;
//       }

//       // 로그인 성공 처리
//       developer.log("✅ 로그인 성공: ${_users[id]}");
//       handler.resolve(Response(
//         requestOptions: options,
//         statusCode: 200,
//         data: {"message": "로그인 성공!"}, // 서버에서 로그인 성공 메시지 반환
//       ));
//     }

//     // 인증번호 검증 요청 처리 (기존 코드)
//     else if (options.path == 'https://mock-api.com/verify-code') {
//       String? email = options.data["email"];
//       String? enteredCode = options.data["code"]; // 'otp' 대신 'code'로 수정

//       if (email == null ||
//           email.isEmpty ||
//           enteredCode == null ||
//           enteredCode.isEmpty) {
//         developer.log("❌ 검증 실패: 이메일 또는 인증번호가 비어 있음!");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "이메일 또는 인증번호 값이 없습니다.",
//         ));
//         return;
//       }

//       // 인증번호 검증
//       if (_codeStore[email] == enteredCode) {
//         developer.log("✅ 인증번호 검증 성공!");
//         handler.resolve(Response(
//             requestOptions: options, statusCode: 200)); // 성공 시 200 상태 코드 반환
//       } else {
//         developer.log("❌ 인증번호 검증 실패! 저장된 인증번호: ${_codeStore[email]}");
//         handler.reject(DioException(
//           requestOptions: options,
//           type: DioExceptionType.badResponse,
//           message: "인증번호가 올바르지 않습니다. 다시 입력해주세요.",
//         ));
//       }
//     }

//     // 그 외의 요청 처리
//     else {
//       handler.next(options);
//     }
//   }
// }
