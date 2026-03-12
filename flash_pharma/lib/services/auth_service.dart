import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../core/constants/app_constants.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // Demo mode — set to false once a real backend is available
  static const bool _demoMode = true;

  // Login
  Future<User> login({required String email, required String password}) async {
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (password.length < 6) throw Exception('401');
      final role = email.toLowerCase().contains('pharmacy') ? 'pharmacy' : 'patient';
      final user = User(
        id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        name: role == 'pharmacy' ? 'Flash Pharmacy' : 'Demo User',
        email: email,
        phone: '+91 9876543210',
        role: role,
        address: '123 Health Street, Mumbai',
        latitude: 19.0760,
        longitude: 72.8777,
        createdAt: DateTime.now(),
      );
      await _storage.saveToken('demo_token_${user.id}');
      await _storage.saveRefreshToken('demo_refresh_${user.id}');
      await _storage.saveRole(user.role);
      await _storage.saveUserData(jsonEncode(user.toJson()));
      return user;
    }

    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _storage.saveToken(response['token'] as String);
    await _storage.saveRefreshToken(response['refresh_token'] as String);
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.saveRole(user.role);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Register Patient
  Future<User> registerPatient({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final user = User(
        id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        role: 'patient',
        address: 'Mumbai, India',
        createdAt: DateTime.now(),
      );
      await _storage.saveToken('demo_token_${user.id}');
      await _storage.saveRefreshToken('demo_refresh_${user.id}');
      await _storage.saveRole(user.role);
      await _storage.saveUserData(jsonEncode(user.toJson()));
      return user;
    }

    final response = await _api.post('/auth/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': 'patient',
    });
    await _storage.saveToken(response['token'] as String);
    await _storage.saveRefreshToken(response['refresh_token'] as String);
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.saveRole(user.role);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Register Pharmacy
  Future<User> registerPharmacy({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final user = User(
        id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        role: 'pharmacy',
        address: address,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
      );
      await _storage.saveToken('demo_token_${user.id}');
      await _storage.saveRefreshToken('demo_refresh_${user.id}');
      await _storage.saveRole(user.role);
      await _storage.saveUserData(jsonEncode(user.toJson()));
      return user;
    }

    final response = await _api.post('/auth/register/pharmacy', data: {
      'name': name,
      'owner_name': ownerName,
      'email': email,
      'phone': phone,
      'password': password,
      'license_number': licenseNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'role': 'pharmacy',
    });
    await _storage.saveToken(response['token'] as String);
    await _storage.saveRefreshToken(response['refresh_token'] as String);
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.saveRole(user.role);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Sign in with Google via Supabase
  Future<User> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      serverClientId: AppConstants.googleWebClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) throw Exception('No ID token from Google');

    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final supabaseUser = response.user;
    if (supabaseUser == null) throw Exception('Supabase sign-in failed');

    final user = User(
      id: supabaseUser.id,
      name: supabaseUser.userMetadata?['full_name'] as String? ??
          supabaseUser.userMetadata?['name'] as String? ??
          googleUser.displayName ??
          'User',
      email: supabaseUser.email ?? googleUser.email,
      phone: supabaseUser.phone ?? '',
      role: 'patient',
      avatarUrl: supabaseUser.userMetadata?['avatar_url'] as String? ??
          googleUser.photoUrl,
      createdAt: DateTime.now(),
    );

    await _storage.saveToken(response.session?.accessToken ?? '');
    await _storage.saveRefreshToken(response.session?.refreshToken ?? '');
    await _storage.saveRole(user.role);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Get current user from storage
  Future<User?> getCurrentUser() async {
    final userData = await _storage.getUserData();
    if (userData == null) return null;
    return User.fromJson(jsonDecode(userData) as Map<String, dynamic>);
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }

  // Get user profile from API
  Future<User> getProfile() async {
    final response = await _api.get('/auth/profile');
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Update profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put('/auth/profile', data: data);
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Logout
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.clearAll();
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    await _api.post('/auth/forgot-password', data: {'email': email});
  }

  // Verify OTP
  Future<void> verifyOtp({required String phone, required String otp}) async {
    await _api.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
  }
}
