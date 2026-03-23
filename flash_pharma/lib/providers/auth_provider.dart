import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get role => _user?.role ?? '';

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.getCurrentUser();
    } catch (_) {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({required String phone, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.login(phone: phone, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerPatient({
    required String name,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.registerPatient(
        name: name,
        phone: phone,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerPharmacy({
    required String name,
    required String ownerName,
    required String phone,
    required String password,
    required String licenseNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.registerPharmacy(
        name: name,
        ownerName: ownerName,
        phone: phone,
        password: password,
        licenseNumber: licenseNumber,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp({required String phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.sendOtp(phone: phone);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.verifyOtp(phone: phone, otp: otp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.updateProfile(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    debugPrint('Auth Error: $e');
    if (e.toString().contains('401')) return 'Invalid phone number or password';
    if (e.toString().contains('invalid') && e.toString().contains('otp')) {
      return 'Invalid OTP. Please try again.';
    }
    if (e.toString().contains('409')) return 'Account already exists';
    if (e.toString().contains('SocketException')) return 'No internet connection';
    return e.toString(); // Show actual error for debugging
  }
}
