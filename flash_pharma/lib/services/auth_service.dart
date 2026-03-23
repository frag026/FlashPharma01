import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();
  final SupabaseClient _supabase = Supabase.instance.client;

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.length > 10) return '+$digits';
    return phone.startsWith('+') ? phone : '+$digits';
  }

  String _pseudoEmailFromPhone(String phone) {
    final normalized = _normalizePhone(phone).replaceAll('+', '');
    return '$normalized@phone.flashpharma.local';
  }

  // Login
  Future<User> login({required String phone, required String password}) async {
    final normalizedPhone = _normalizePhone(phone);
    final pseudoEmail = _pseudoEmailFromPhone(normalizedPhone);

    final response = await _supabase.auth.signInWithPassword(
      email: pseudoEmail,
      password: password,
    );

    final supaUser = response.user;
    if (supaUser == null) throw Exception('Login failed');

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', supaUser.id)
        .single();

    final user = User.fromJson(profile);

    await _storage.saveToken(response.session?.accessToken ?? '');
    await _storage.saveRefreshToken(response.session?.refreshToken ?? '');
    await _storage.saveRole(user.role);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Send OTP for phone auth
  Future<void> sendOtp({required String phone}) async {
    final normalizedPhone = _normalizePhone(phone);
    await _supabase.auth.signInWithOtp(phone: normalizedPhone);
  }

  Future<User> _loadAndCacheUserFromAuthUserId(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final user = User.fromJson(profile);
    final session = _supabase.auth.currentSession;

    await _storage.saveToken(session?.accessToken ?? '');
    await _storage.saveRefreshToken(session?.refreshToken ?? '');
    await _storage.saveRole(user.role);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Register Patient
  Future<User> registerPatient({
    required String name,
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final pseudoEmail = _pseudoEmailFromPhone(normalizedPhone);

    final response = await _supabase.auth.signUp(
      email: pseudoEmail,
      password: password,
      data: {
        'name': name,
        'phone': normalizedPhone,
        'role': 'patient',
      },
    );

    final supaUser = response.user;
    if (supaUser == null) throw Exception('Registration failed');

    // Wait briefly for the trigger to create the profile
    await Future.delayed(const Duration(milliseconds: 500));

    // Update profile with extra fields
    await _supabase.from('profiles').update({
      'name': name,
      'phone': normalizedPhone,
      'email': pseudoEmail,
      'role': 'patient',
    }).eq('id', supaUser.id);

    final user = User(
      id: supaUser.id,
      name: name,
      email: pseudoEmail,
      phone: normalizedPhone,
      role: 'patient',
      createdAt: DateTime.now(),
    );

    await _storage.saveToken(response.session?.accessToken ?? '');
    await _storage.saveRefreshToken(response.session?.refreshToken ?? '');
    await _storage.saveRole(user.role);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Register Pharmacy
  Future<User> registerPharmacy({
    required String name,
    required String ownerName,
    required String phone,
    required String password,
    required String licenseNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final pseudoEmail = _pseudoEmailFromPhone(normalizedPhone);

    final response = await _supabase.auth.signUp(
      email: pseudoEmail,
      password: password,
      data: {
        'name': name,
        'phone': normalizedPhone,
        'role': 'pharmacy',
      },
    );

    final supaUser = response.user;
    if (supaUser == null) throw Exception('Registration failed');

    // Wait briefly for the trigger to create the profile
    await Future.delayed(const Duration(milliseconds: 500));

    // Update profile
    await _supabase.from('profiles').update({
      'name': name,
      'phone': normalizedPhone,
      'email': pseudoEmail,
      'role': 'pharmacy',
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    }).eq('id', supaUser.id);

    // Create pharmacy record
    await _supabase.from('pharmacies').insert({
      'owner_id': supaUser.id,
      'name': name,
      'owner_name': ownerName,
      'email': pseudoEmail,
      'phone': normalizedPhone,
      'license_number': licenseNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });

    final user = User(
      id: supaUser.id,
      name: name,
      email: pseudoEmail,
      phone: normalizedPhone,
      role: 'pharmacy',
      address: address,
      latitude: latitude,
      longitude: longitude,
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

  // Get user profile from Supabase
  Future<User> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final user = User.fromJson(profile);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Update profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('profiles').update(data).eq('id', userId);

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final user = User.fromJson(profile);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    await _storage.clearAll();
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Verify OTP and sign in user
  Future<User> verifyOtp({required String phone, required String otp}) async {
    final normalizedPhone = _normalizePhone(phone);

    final response = await _supabase.auth.verifyOTP(
      phone: normalizedPhone,
      token: otp,
      type: OtpType.sms,
    );

    final authUser = response.user ?? _supabase.auth.currentUser;
    if (authUser == null) throw Exception('OTP verification failed');

    return _loadAndCacheUserFromAuthUserId(authUser.id);
  }
}
