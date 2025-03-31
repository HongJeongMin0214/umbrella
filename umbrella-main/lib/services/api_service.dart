import 'package:dio/dio.dart';
import 'package:umbrella/services/mock_api_interceptor.dart';
import 'dart:developer' as developer;

class ApiService {
  final Dio _dio = Dio();

  ApiService() {
    _dio.interceptors.add(MockApiInterceptor());
  }

  // 이메일 인증번호 전송 요청
  Future<String> sendVerificationCode(String email) async {
    try {
      developer.log("🛠️ 이메일 인증 요청 - 이메일: $email");

      final response = await _dio.post(
        'https://mock-api.com/send-email',
        data: {"email": email},
      );

      if (response.statusCode == 200) {
        developer.log("✅ 인증번호 전송 성공");
        return "success";
      } else {
        //인증번호 이미 존재하는지
        developer.log("❌ 이메일 이미 존재. 인증번호 전송 실패, 상태 코드: ${response.statusCode}");
        return "email_exists";
      }
    } catch (e) {
      developer.log("❌ 이메일 인증 오류: $e");
      return "error";
    }
  }

  // 인증번호 검증 요청
  Future<bool> verifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        'https://mock-api.com/verify-code', // 경로를 verify-code로 수정
        data: {"email": email, "code": code}, // 'otp' 대신 'code' 사용
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

  // 회원가입 요청 메소드
  Future<bool> registerUser(String name, String id, String password) async {
    try {
      developer.log("🛠️ 회원가입 요청 - 이름: $name, 아이디: $id, 비밀번호: $password");
      // 서버로 요청을 보내는 코드
      final response = await _dio.post(
        'https://mock-api.com/register', // 서버에서 정의한 회원가입 API 경로
        data: {
          "name": name,
          "id": id,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        developer.log("✅ 회원가입 성공: ${response.data}");
        return true;
      } else {
        developer.log("❌ 회원가입 실패, 상태 코드: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      // 예외가 발생한 경우 에러 로그
      developer.log("❌ 회원가입 오류: $e");
      return false;
    }
  }

  // 로그인 요청
  Future<bool> loginUser(String id, String password) async {
    try {
      developer.log("🛠️ 로그인 요청 - 아이디: $id, 비밀번호: $password");

      final response = await _dio.post(
        'https://mock-api.com/login', // 서버에서 정의한 로그인 API 경로
        data: {
          "id": id,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        developer.log("✅ 로그인 성공: ${response.data}");
        return true; // 로그인 성공
      } else {
        developer.log("❌ 로그인 실패, 상태 코드: ${response.statusCode}");
        return false; // 로그인 실패
      }
    } catch (e) {
      developer.log("❌ 로그인 오류: $e");
      return false; // 에러 발생 시 실패
    }
  }
}

//   // ✅ 아이디 중복 확인 API 추가
//   Future<bool> checkUsername(String username) async {
//     // 아이디 중복 확인 버튼 누르면 호출
//     try {
//       final response = await _dio.get(
//         'https://mock-api.com/check-username',
//         queryParameters: {
//           "username": username
//         }, // 입력한 username을 서버에 보내 이미 존재하는지 확인
//       );
//       return response.statusCode == 200 &&
//           response.data['available']; //응답 데이터에서 "available":true이면 사용 가능
//     } catch (e) {
//       developer.log("❌ 아이디 중복 확인 실패: $e");
//       return false;
//     }
//   }

// import 'package:dio/dio.dart';
// import 'dart:developer' as developer;

// class ApiService {
//   // final Dio _dio = Dio(BaseOptions(
//   //   baseUrl: 'https://your-api-url.com',
//   // ));

//   // 이메일 인증번호 전송을 요청하는 함수
//   Future<bool> sendVerificationCode(String email) async {
//     try {
//       developer.log("🛠️ 이메일 인증 요청 - 이메일: $email");

//       // final response = await _dio.post(
//       //   '/auth/email-verification', // API 경로는 실제 서버에 맞게 변경
//       //   data: {"email": email},
//       // );

//       // if (response.statusCode == 200) {
//       //   developer.log("✅ 인증번호 전송 성공");
//       //   return true;
//       // } else {
//       //   developer.log("❌ 인증번호 전송 실패 - 응답 코드: ${response.statusCode}");
//       //   return false;
//       // }
//       await Future.delayed(const Duration(seconds: 2));
//       return true;
//     } catch (e) {
//       developer.log("❌ 이메일 인증 오류: $e");
//       return false;
//     }
//   }

//   // 인증번호 검증 요청을 서버에 보내는 함수
//   Future<bool> verifyCode(String email, String code) async {
//     try {
//       developer.log("🛠️ 인증번호 검증 요청 - 이메일: $email, 인증번호: $code");

//       // final response = await _dio.post(
//       //   '/auth/email-verification', // 실제 API 경로로 수정
//       //   data: {"email": email, "code": code}, // 인증번호와 이메일을 함께 전송
//       // );

//       // return response.statusCode == 200;
//       await Future.delayed(const Duration(seconds: 2));
//       return true;
//     } catch (e) {
//       developer.log("❌ 인증번호 검증 오류: $e");
//       return false;
//     }
//   }
// }
