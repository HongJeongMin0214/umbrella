import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UserProvider extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';

  String? _token;
  Map<String, dynamic>? _userData; // JWT 디코딩된 사용자 데이터

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _token != null;

  // 앱 시작 시 호출하여 SharedPreferences에서 토큰을 불러오기
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    if (storedToken != null && !JwtDecoder.isExpired(storedToken)) {
      _token = storedToken;
      _userData = JwtDecoder.decode(storedToken); // JWT 디코딩하여 사용자 데이터 가져오기
      notifyListeners();
    }
  }

  // 로그인 시 토큰을 저장하고 디코딩된 사용자 데이터도 저장
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _userData = JwtDecoder.decode(token); // JWT 디코딩하여 사용자 데이터 저장
    await prefs.setString(_tokenKey, token);
    notifyListeners();
  }

  // 로그아웃 시 토큰과 사용자 데이터 제거
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _userData = null;
    await prefs.remove(_tokenKey); // SharedPreferences에서 토큰 제거
    notifyListeners();
  }

  // 사용자 ID와 이름을 쉽게 가져올 수 있도록 getter 추가
  String? get userId => _userData?['id']; // 디코딩된 데이터에서 'id' 필드 가져오기
  String? get userName => _userData?['name']; // 디코딩된 데이터에서 'name' 필드 가져오기
}
