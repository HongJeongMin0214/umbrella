import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/provider/user_provider.dart';
import 'auth_service.dart';
import 'mock_api_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/provider/user_provider.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://mock-api.com';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(MockApiInterceptor());
  }

  Future<String> sendVerificationCode(
      String email, bool isPasswordReset) async {
    developer.log("🛠️ 이메일 인증 요청 - 이메일: $email, 비밀번호 변경: $isPasswordReset");

    try {
      final response = await _dio.post(
        '/send-email',
        data: {"email": email},
        queryParameters: {
          "isPasswordReset": isPasswordReset.toString(),
        },
      );

      if (response.statusCode == 200) {
        return _handleSuccess(isPasswordReset);
      }

      if (isPasswordReset) {
        return _handleError(response, "비밀번호 변경 이메일 인증 오류");
      }

      return _handleError(response, "회원가입 이메일 인증 오류");
    } catch (e) {
      if (e is DioException) {
        return _handleNetworkError(e);
      }
      developer.log("❌ 예외 발생: ${e.toString()}");
      return "error";
    }
  }

  String _handleSuccess(bool isPasswordReset) {
    String logMessage =
        isPasswordReset ? "비밀번호 변경 이메일 인증번호 전송 성공" : "회원가입 이메일 인증번호 전송 성공";
    developer.log("✅ $logMessage");
    return "success";
  }

  String _handleError(Response response, String logPrefix) {
    String errorMessage = _getErrorMessage(response);
    developer.log("❌ $logPrefix: ${response.statusCode} - $errorMessage");

    if (response.statusCode == 404) {
      if (response.data is Map &&
          response.data['message'] == 'Email not found') {
        return "changepw_email_not_exists";
      } else if (response.data['message'] == 'Email already exists') {
        return "signup_email_exists";
      }
    } else if (response.statusCode == 401) {
      return "error_unauthorized";
    } else if (response.statusCode == 500) {
      return _handleServerError(response);
    }

    return "error";
  }

  String _handleNetworkError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      developer.log("❌ 네트워크 연결 시간 초과");
      return "error_timeout";
    } else if (e.type == DioExceptionType.receiveTimeout) {
      developer.log("❌ 서버 응답 시간 초과");
      return "error_server_timeout";
    } else if (e.type == DioExceptionType.unknown) {
      developer.log("❌ 네트워크 오류: ${e.message}");
      return "error_network";
    }
    return "error";
  }

  String _handleServerError(Response response) {
    developer.log("❌ 서버 오류: ${response.statusCode}");
    return "error_server";
  }

  String _getErrorMessage(Response response) {
    if (response.data != null) {
      return response.data['message'] ??
          response.data['error'] ??
          response.data['error_message'] ??
          'Unknown error';
    }
    return 'Unknown error';
  }

  Future<bool> verifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        '/verify-code',
        data: {"email": email, "code": code},
      );

      if (response.statusCode == 200) {
        developer.log("✅ 인증번호 검증 성공");
        return true;
      } else {
        developer.log("❌ 인증번호 검증 실패, 상태 코드: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("❌ 인증번호 검증 오류: $e");
      return false;
    }
  }

  Future<bool> registerUser(
      String name, String id, String password, String email) async {
    try {
      developer.log(
          "🛠️ 회원가입 요청 - 이름: $name, 아이디: $id, 비밀번호: $password, 이메일: $email");

      final response = await _dio.post('/register', data: {
        "name": name,
        "id": id,
        "password": password,
        "email": email,
      });

      if (response.statusCode == 200) {
        developer.log("✅ 회원가입 성공: ${response.data}");
        return true;
      } else {
        developer.log("❌ 회원가입 실패, 상태 코드: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("❌ 회원가입 오류: $e");
      return false;
    }
  }

  Future<bool> changePw(
      String email, String currentPassword, String newPassword) async {
    try {
      developer.log(
          "🛠️ 비번 변경 요청 - 현재 비밀번호: $currentPassword, 새 비밀번호: $newPassword");

      final response = await _dio.post(
        '/changePw',
        data: {
          'email': email,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        developer.log("✅ 비번 변경 성공: ${response.data}");
        return true;
      } else {
        developer.log("❌ 비번 변경 실패, 상태 코드: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("❌ 비밀번호 변경 오류: $e");
      return false;
    }
  }

  /// ✅ 로그인 요청 → 성공 시 provider에 토큰 저장
  Future<bool> loginUser(
      BuildContext context, String id, String password) async {
    try {
      developer.log("🛠️ 로그인 요청 - 아이디: $id, 비밀번호: $password");

      final response = await _dio.post(
        '/login',
        data: {"id": id, "password": password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];

        // provider를 통해 토큰 저장 + 유저 정보 저장
        await context.read<UserProvider>().saveToken(token);

        return true;
      } else {
        developer.log("❌ 로그인 실패, 상태 코드: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("❌ 로그인 오류: $e");
      return false;
    }
  }

  /// ✅ 예시: 대여 이력 조회
  Future<List<dynamic>?> getRentalHistory(BuildContext context) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '/rental-history',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      developer.log("❌ 대여 이력 조회 오류: $e");
      return null;
    }
  }

  /// ✅ 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile(BuildContext context) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '/profile',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      developer.log("❌ 프로필 조회 오류: $e");
      return null;
    }
  }
}


// import 'package:dio/dio.dart';
// import 'dart:developer' as developer;
// import 'package:umbrella/services/mock_api_interceptor.dart';

// class ApiService {
//   final Dio _dio = Dio();
//   final String baseUrl = 'https://mock-api.com';

//   ApiService() {
//     _dio.options.baseUrl = baseUrl;
//     _dio.interceptors.add(MockApiInterceptor());
//   }

//   Future<String> sendVerificationCode(
//       String email, bool isPasswordReset) async {
//     developer.log("🛠️ 이메일 인증 요청 - 이메일: $email, 비밀번호 변경: $isPasswordReset");

//     try {
//       final response = await _dio.post(
//         '/send-email',
//         data: {"email": email},
//         queryParameters: {
//           "isPasswordReset": isPasswordReset.toString(), // 문자열로 변환
//         },
//       );

//       if (response.statusCode == 200) {
//         return _handleSuccess(isPasswordReset);
//       }

//       if (isPasswordReset) {
//         return _handleError(response, "비밀번호 변경 이메일 인증 오류");
//       }

//       return _handleError(response, "회원가입 이메일 인증 오류");
//     } catch (e) {
//       if (e is DioException) {
//         return _handleNetworkError(e);
//       }
//       developer.log("❌ 예외 발생: ${e.toString()}");
//       return "error";
//     }
//   }

//   String _handleSuccess(bool isPasswordReset) {
//     String logMessage =
//         isPasswordReset ? "비밀번호 변경 이메일 인증번호 전송 성공" : "회원가입 이메일 인증번호 전송 성공";
//     developer.log("✅ $logMessage");
//     return "success";
//   }

//   String _handleError(Response response, String logPrefix) {
//     String errorMessage = _getErrorMessage(response);
//     developer.log("❌ $logPrefix: ${response.statusCode} - $errorMessage");

//     if (response.statusCode == 404) {
//       if (response.data is Map &&
//           response.data['message'] == 'Email not found') {
//         return "changepw_email_not_exists";
//       } else if (response.data['message'] == 'Email already exists') {
//         return "signup_email_exists";
//       }
//     } else if (response.statusCode == 401) {
//       return "error_unauthorized";
//     } else if (response.statusCode == 500) {
//       return _handleServerError(response);
//     }

//     return "error";
//   }

//   String _handleNetworkError(DioException e) {
//     if (e.type == DioExceptionType.connectionTimeout) {
//       developer.log("❌ 네트워크 연결 시간 초과");
//       return "error_timeout";
//     } else if (e.type == DioExceptionType.receiveTimeout) {
//       developer.log("❌ 서버 응답 시간 초과");
//       return "error_server_timeout";
//     } else if (e.type == DioExceptionType.unknown) {
//       developer.log("❌ 네트워크 오류: ${e.message}");
//       return "error_network";
//     }
//     return "error";
//   }

//   String _handleServerError(Response response) {
//     developer.log("❌ 서버 오류: ${response.statusCode}");
//     return "error_server";
//   }

//   String _getErrorMessage(Response response) {
//     if (response.data != null) {
//       return response.data['message'] ??
//           response.data['error'] ??
//           response.data['error_message'] ??
//           'Unknown error';
//     }
//     return 'Unknown error';
//   }

//   Future<bool> verifyCode(String email, String code) async {
//     try {
//       final response = await _dio.post(
//         '/verify-code',
//         data: {"email": email, "code": code},
//       );

//       if (response.statusCode == 200) {
//         developer.log("✅ 인증번호 검증 성공");
//         return true;
//       } else {
//         developer.log("❌ 인증번호 검증 실패, 상태 코드: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       developer.log("❌ 인증번호 검증 오류: $e");
//       return false;
//     }
//   }

//   Future<bool> registerUser(
//       String name, String id, String password, String email) async {
//     try {
//       developer.log(
//           "🛠️ 회원가입 요청 - 이름: $name, 아이디: $id, 비밀번호: $password, 이메일: $email");

//       final response = await _dio.post('/register', data: {
//         "name": name,
//         "id": id,
//         "password": password,
//         "email": email,
//       });

//       if (response.statusCode == 200) {
//         developer.log("✅ 회원가입 성공: ${response.data}");
//         return true;
//       } else {
//         developer.log("❌ 회원가입 실패, 상태 코드: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       developer.log("❌ 회원가입 오류: $e");
//       return false;
//     }
//   }

//   Future<bool> changePw(
//       String email, String currentPassword, String newPassword) async {
//     try {
//       developer.log(
//           "🛠️ 비번 변경 요청 - 현재 비밀번호: $currentPassword, 새 비밀번호: $newPassword");

//       final response = await _dio.post(
//         '/changePw',
//         data: {
//           'email': email,
//           'currentPassword': currentPassword,
//           'newPassword': newPassword,
//         },
//       );

//       if (response.statusCode == 200) {
//         developer.log("✅ 비번 변경 성공: ${response.data}");
//         return true;
//       } else {
//         developer.log("❌ 비번 변경 실패, 상태 코드: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       developer.log("❌ 비밀번호 변경 오류: $e");
//       return false;
//     }
//   }

//   Future<bool> loginUser(String id, String password) async {
//     try {
//       developer.log("🛠️ 로그인 요청 - 아이디: $id, 비밀번호: $password");

//       final response = await _dio.post(
//         '/login',
//         data: {"id": id, "password": password},
//       );

//       if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final token = data['token'];
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_tokenKey, token);
//       return true;
//         developer.log("✅ 로그인 성공: ${response.data}");
//         return true;
//       } else {
//         developer.log("❌ 로그인 실패, 상태 코드: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       developer.log("❌ 로그인 오류: $e");
//       return false;
//     }
//       Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_tokenKey);
//   }

//   Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_tokenKey);
//   }

//   Future<Map<String, dynamic>?> getUserProfile() async {
//     final token = await getToken();
//     if (token == null) return null;

//     final response = await _dio.get(
//       Uri.parse('$baseUrl/profile'),
//       headers: {'Authorization': 'Bearer $token'},
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     return null;
//   }

//   Future<String?> getUserIdFromToken() async {
//     final token = await getToken();
//     if (token == null) return null;
//     final decoded = JwtDecoder.decode(token);
//     return decoded['id']; // 백엔드에서 토큰에 어떤 필드를 넣는지에 따라 변경
//   }
//   }
// }

// import 'package:dio/dio.dart';
// import 'dart:developer' as developer;

// class ApiService {
//   final Dio _dio = Dio();
//   final String baseUrl = 'https://mock-api.com'; //http://54.180.32.62:8080

//   ApiService() {
//     _dio.options.baseUrl = baseUrl;
//   }

//   Future<String> sendVerificationCode(
//       String email, bool isPasswordReset) async {
//     developer.log("🛠️ 이메일 인증 요청 - 이메일: $email, 비밀번호 변경: $isPasswordReset");

//     try {
//       final response = await _dio.post(
//         '/send-email',
//         data: {"email": email},
//         queryParameters: {
//           "isPasswordReset": isPasswordReset,
//         },
//       );

//       // 상태 코드 200일 때 처리
//       if (response.statusCode == 200) {
//         return _handleSuccess(isPasswordReset);
//       }

//       // 비밀번호 변경 처리
//       if (isPasswordReset) {
//         return _handleError(response, "비밀번호 변경 이메일 인증 오류");
//       }

//       // 회원가입 처리
//       return _handleError(response, "회원가입 이메일 인증 오류");
//     } catch (e) {
//       // 네트워크 관련 오류 처리 (timeout, connection error 등)
//       if (e is DioException) {
//         return _handleNetworkError(e);
//       }
//       // 일반적인 예외 처리
//       developer.log("❌ 예외 발생: ${e.toString()}");
//       return "error";
//     }
//   }

//   // 이메일 인증 성공 처리
//   String _handleSuccess(bool isPasswordReset) {
//     String logMessage =
//         isPasswordReset ? "비밀번호 변경 이메일 인증번호 전송 성공" : "회원가입 이메일 인증번호 전송 성공";
//     developer.log("✅ $logMessage");
//     return "success";
//   }

//   // 공통 오류 처리
//   String _handleError(Response response, String logPrefix) {
//     String errorMessage = _getErrorMessage(response);
//     developer.log("❌ $logPrefix: ${response.statusCode} - $errorMessage");

//     // 상태 코드에 따른 처리
//     if (response.statusCode == 404) {
//       if (response.data is Map &&
//           response.data['message'] == 'Email not found') {
//         return "changepw_email_not_exists"; // 비밀번호 변경시 이메일이 없으면
//       } else if (response.data['message'] == 'Email already exists') {
//         return "signup_email_exists"; // 회원가입시 이메일이 이미 존재하면
//       }
//     } else if (response.statusCode == 401) {
//       return "error_unauthorized"; // 권한 오류
//     } else if (response.statusCode == 500) {
//       return _handleServerError(response);
//     }

//     return "error"; // 기타 오류
//   }

//   // 네트워크 오류 처리
//   String _handleNetworkError(DioException e) {
//     if (e.type == DioExceptionType.connectionTimeout) {
//       developer.log("❌ 네트워크 연결 시간 초과");
//       return "error_timeout";
//     } else if (e.type == DioExceptionType.receiveTimeout) {
//       developer.log("❌ 서버 응답 시간 초과");
//       return "error_server_timeout";
//     } else if (e.type == DioExceptionType.unknown) {
//       developer.log("❌ 네트워크 오류: ${e.message}");
//       return "error_network";
//     }
//     return "error";
//   }

//   // 서버 오류 처리 (공통)
//   String _handleServerError(Response response) {
//     developer.log("❌ 서버 오류: ${response.statusCode}");
//     return "error_server";
//   }

//   // 오류 메시지 처리
//   String _getErrorMessage(Response response) {
//     if (response.data != null) {
//       // message > error > error_message 순으로 확인
//       return response.data['message'] ??
//           response.data['error'] ??
//           response.data['error_message'] ??
//           'Unknown error';
//     }
//     return 'Unknown error';
//   }

// // 이메일 인증번호 전송 요청
// //   Future<String> sendVerificationCode(
// //       String email, bool isPasswordReset) async {
// //       developer.log("🛠️ 이메일 인증 요청 - 이메일: $email, 비밀번호 변경: $isPasswordReset");
// //     try {
// //       final response = await _dio.post(
// //         '/auth/email-verification',
// //         data: {"email": email},
// //         queryParameters: {
// //           "isPasswordReset": isPasswordReset
// //               .toString() // isPasswordReset 값이 true 또는 false로 URL에 추가
// //         },
// //       );

// //     if (isPasswordReset) { // 비밀번호 변경 이메일 인증
// //       if (response.statusCode == 200) {
// //         developer.log("✅ 비밀번호 변경 이메일 인증번호 전송 성공");
// //         return "success";
// //       } else if (response.statusCode == 404) {
// //         developer.log("비밀번호 변경할 이메일이 존재하지 않음 ");
// //         return "changepw_email_not_exists";
// //       } else {
// //         developer.log("❌ 비밀번호 변경 이메일 인증 오류: ${response.statusCode}");
// //         return "error";
// //       }
// //     } else { // 회원가입 이메일 인증
// //       if (response.statusCode == 200) {
// //         developer.log("✅ 인증번호 전송 성공");
// //         return "success";
// //       } else if (response.statusCode == 400) {
// //         developer.log("이미 가입된 이메일");
// //         return "signup_email_exists";
// //       } else {
// //         developer.log("❌ 회원가입 이메일 인증 오류: ${response.statusCode}");
// //         return "error";
// //       }
// //     }
// // } catch (e) {
// //   developer.log("❌ 예외 발생: $e");
// //   return "error";
// // }}
//   //   if (response.statusCode == 200) {

//   //     developer.log("✅ 인증번호 전송 성공");
//   //     return "success";
//   //   } else if (isPasswordReset) {
//   //     if (response.statusCode == 200) {
//   //       developer.log("✅ 비밀번호 변경 이메일 인증 성공");
//   //       return "success";
//   //     } else {
//   //       developer.log("비밀번호 변경 이메일 존재하지 않음 ");
//   //       return "email_exists";
//   //     }

//   //     // 비밀번호 변경 시 이미 존재하는 이메일이라면 인증번호 전송
//   //   } else {
//   //     developer.log("❌ 이메일 이미 존재. 인증번호 전송 실패, 상태 코드: ${response.statusCode}");
//   //     return "email_exists";
//   //   }
//   // } catch (e) {
//   //   developer.log("❌ 이메일 인증 오류: $e");
//   //   return "error";
//   // }

//   // 인증번호 검증 요청
//   Future<bool> verifyCode(String email, String code) async {
//     try {
//       final response = await _dio.post(
//         '/verify-code', //   /auth/verify-code
//         data: {"email": email, "code": code},
//       );

//       if (response.statusCode == 200) {
//         developer.log("✅ 인증번호 검증 성공");
//         return true;
//       } else {
//         developer.log("❌ 인증번호 검증 실패, 상태 코드: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       developer.log("❌ 인증번호 검증 오류: $e");
//       return false;
//     }
//   }

//   // 회원가입 요청 메소드
//   Future<bool> registerUser(String name, String id, String password) async {
//     try {
//       developer.log("🛠️ 회원가입 요청 - 이름: $name, 아이디: $id, 비밀번호: $password");
//       // 서버로 요청을 보내는 코드
//       final response = await _dio.post(
//         '/register',
//         data: {
//           "name": name,
//           "id": id,
//           "password": password,
//         },
//       );

//       if (response.statusCode == 200) {
//         developer.log("✅ 회원가입 성공: ${response.data}");
//         return true;
//       } else {
//         developer.log("❌ 회원가입 실패, 상태 코드: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       // 예외가 발생한 경우 에러 로그
//       developer.log("❌ 회원가입 오류: $e");
//       return false;
//     }
//   }

//   Future<bool> changePw(String password) async {
//     try {
//       developer.log("🛠️ 비번 변경 요청 - 비밀번호: $password");

//       final response = await _dio.post(
//         '/changePw',
//         data: {
//           "password": password,
//         },
//       );

//       if (response.statusCode == 200) {
//         developer.log("✅ 비번 변경 성공: ${response.data}");
//         return true;
//       } else {
//         developer.log("❌ 비번 변경 실패, 상태 코드: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       developer.log("❌ 회원가입 오류: $e");
//       return false;
//     }
//   }

//   // 로그인 요청
//   Future<bool> loginUser(String id, String password) async {
//     try {
//       developer.log("🛠️ 로그인 요청 - 아이디: $id, 비밀번호: $password");

//       final response = await _dio.post(
//         '/login',
//         data: {
//           "id": id,
//           "password": password,
//         },
//       );

//       if (response.statusCode == 200) {
//         developer.log("✅ 로그인 성공: ${response.data}");
//         return true;
//       } else {
//         developer.log("❌ 로그인 실패, 상태 코드: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       developer.log("❌ 로그인 오류: $e");
//       return false;
//     }
//   }
// }


// // import 'package:dio/dio.dart';
// // import 'package:umbrella/services/mock_api_interceptor.dart';
// // import 'dart:developer' as developer;

// // class ApiService {
// //   final Dio _dio = Dio();

// //   ApiService() {
// //     _dio.interceptors.add(MockApiInterceptor());
// //   }

// //   // 이메일 인증번호 전송 요청
// //   Future<String> sendVerificationCode(
// //       String email, bool isPasswordReset) async {
// //     try {
// //       developer.log("🛠️ 이메일 인증 요청 - 이메일: $email, 비밀번호 변경: $isPasswordReset");

// //       final response = await _dio.post(
// //         'https://mock-api.com/send-email',
// //         data: {"email": email},
// //         queryParameters: {
// //           "isPasswordReset": isPasswordReset
// //               .toString() // isPasswordReset 값이 true 또는 false로 URL에 추가
// //         },
// //       );

// //       if (response.statusCode == 200) {
// //         developer.log("✅ 인증번호 전송 성공");
// //         return "success";
// //       } else if (isPasswordReset) {
// //         if (response.statusCode == 200) {
// //           developer.log("✅ 비밀번호 변경 이메일 인증 성공");
// //           return "success";
// //         } else {
// //           developer.log("비밀번호 변경 이메일 존재하지 않음 ");
// //           return "email_exists";
// //         }

// //         // 비밀번호 변경 시 이미 존재하는 이메일이라면 인증번호 전송
// //       } else {
// //         developer.log("❌ 이메일 이미 존재. 인증번호 전송 실패, 상태 코드: ${response.statusCode}");
// //         return "email_exists";
// //       }
// //     } catch (e) {
// //       developer.log("❌ 이메일 인증 오류: $e");
// //       return "error";
// //     }
// //   }

// //   // 인증번호 검증 요청
// //   Future<bool> verifyCode(String email, String code) async {
// //     try {
// //       final response = await _dio.post(
// //         'https://mock-api.com/verify-code', // 경로를 verify-code로 수정
// //         data: {"email": email, "code": code}, // 'otp' 대신 'code' 사용
// //       );

// //       if (response.statusCode == 200) {
// //         developer.log("✅ 인증번호 검증 성공");
// //         return true;
// //       } else {
// //         developer.log("❌ 인증번호 검증 실패, 상태 코드: ${response.statusCode}");
// //         return false;
// //       }
// //     } catch (e) {
// //       developer.log("❌ 인증번호 검증 오류: $e");
// //       return false;
// //     }
// //   }

// //   // 회원가입 요청 메소드
// //   Future<bool> registerUser(String name, String id, String password) async {
// //     try {
// //       developer.log("🛠️ 회원가입 요청 - 이름: $name, 아이디: $id, 비밀번호: $password");
// //       // 서버로 요청을 보내는 코드
// //       final response = await _dio.post(
// //         'https://mock-api.com/register', // 서버에서 정의한 회원가입 API 경로
// //         data: {
// //           "name": name,
// //           "id": id,
// //           "password": password,
// //         },
// //       );

// //       if (response.statusCode == 200) {
// //         developer.log("✅ 회원가입 성공: ${response.data}");
// //         return true;
// //       } else {
// //         developer.log("❌ 회원가입 실패, 상태 코드: ${response.statusCode}");
// //         return false;
// //       }
// //     } catch (e) {
// //       // 예외가 발생한 경우 에러 로그
// //       developer.log("❌ 회원가입 오류: $e");
// //       return false;
// //     }
// //   }

// //   Future<bool> changePw(String password) async {
// //     try {
// //       developer.log("🛠️ 비번 변경 요청 - 비밀번호: $password");
// //       // 서버로 요청을 보내는 코드
// //       final response = await _dio.post(
// //         'https://mock-api.com/register', // 서버에서 정의한 회원가입 API 경로
// //         data: {
// //           "password": password,
// //         },
// //       );

// //       if (response.statusCode == 200) {
// //         developer.log("✅ 비번 변경 성공: ${response.data}");
// //         return true;
// //       } else {
// //         developer.log("❌ 비번 변경 실패, 상태 코드: ${response.statusCode}");
// //         return false;
// //       }
// //     } catch (e) {
// //       developer.log("❌ 회원가입 오류: $e");
// //       return false;
// //     }
// //   }

// //   // 로그인 요청
// //   Future<bool> loginUser(String id, String password) async {
// //     try {
// //       developer.log("🛠️ 로그인 요청 - 아이디: $id, 비밀번호: $password");

// //       final response = await _dio.post(
// //         'https://mock-api.com/login', // 서버에서 정의한 로그인 API 경로
// //         data: {
// //           "id": id,
// //           "password": password,
// //         },
// //       );

// //       if (response.statusCode == 200) {
// //         developer.log("✅ 로그인 성공: ${response.data}");
// //         return true; // 로그인 성공
// //       } else {
// //         developer.log("❌ 로그인 실패, 상태 코드: ${response.statusCode}");
// //         return false; // 로그인 실패
// //       }
// //     } catch (e) {
// //       developer.log("❌ 로그인 오류: $e");
// //       return false; // 에러 발생 시 실패
// //     }
// //   }
// // }

