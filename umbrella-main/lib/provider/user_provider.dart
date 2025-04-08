import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UserProvider extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';

  String? _token;
  Map<String, dynamic>? _userData;

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _token != null;

  // 앱 시작 시 호출
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    if (storedToken != null && !JwtDecoder.isExpired(storedToken)) {
      _token = storedToken;
      _userData = JwtDecoder.decode(storedToken);
      notifyListeners();
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _userData = JwtDecoder.decode(token);
    await prefs.setString(_tokenKey, token);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _userData = null;
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  String? get userId => _userData?['id'];
  String? get userName => _userData?['name'];
}
