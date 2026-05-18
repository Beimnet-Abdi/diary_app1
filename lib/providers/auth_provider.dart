import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _error = '';

  String? _profileImagePath;
  String _role = 'Software Engineering Student';
  String _organization = 'Addis Ababa University';

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get error => _error;

  String? get profileImagePath => _profileImagePath;
  String get role => _role;
  String get organization => _organization;

  final ApiService _apiService = ApiService();

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Using the service we wrote earlier
      bool success = await _apiService.login(email, password);
      _isLoggedIn = success;

      if (!success) {
        _error = "Invalid email or password";
      }
    } catch (e) {
      _error = "Connection failed. Please try again.";
    }

    _isLoading = false;
    notifyListeners();
    return _isLoggedIn;
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void updateProfile({String? imagePath, String? role, String? organization}) {
    if (imagePath != null) _profileImagePath = imagePath;
    if (role != null) _role = role;
    if (organization != null) _organization = organization;
    notifyListeners();
  }
}
