import 'package:flutter/foundation.dart';

class GlobalState with ChangeNotifier {
  String _username = '';
  String get username => _username;

  String _email = '';
  String get email => _email;

  String _userId = '';
  String get userId => _userId;

  String _token = '';
  String get token => _token;

  String _phone = '';
  String get phone => _phone;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  void setPhone(String phone) {
    _phone = phone;
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
}
