import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../core/constants/app_constants.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Login
  Future<User> login({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
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

  // Register Patient
  Future<User> registerPatient({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
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
      'phone': phone,
      'role': 'patient',
    }).eq('id', supaUser.id);

    final user = User(
      id: supaUser.id,
      name: name,
      email: email,
      phone: phone,
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
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
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
      'phone': phone,
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
      'email': email,
      'phone': phone,
      'license_number': licenseNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });

    final user = User(
      id: supaUser.id,
      name: name,
      email: email,
      phone: phone,
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

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final supabaseUser = response.user;
    if (supabaseUser == null) throw Exception('Supabase sign-in failed');

    // The trigger auto-creates the profile; update with Google info
    await _supabase.from('profiles').upsert({
      'id': supabaseUser.id,
      'name': supabaseUser.userMetadata?['full_name'] ??
          supabaseUser.userMetadata?['name'] ??
          googleUser.displayName ??
          'User',
      'email': supabaseUser.email ?? googleUser.email,
      'phone': supabaseUser.phone ?? '',
      'role': 'patient',
      'avatar_url': supabaseUser.userMetadata?['avatar_url'] ??
          googleUser.photoUrl,
    });

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

  // Verify OTP
  Future<void> verifyOtp({required String phone, required String otp}) async {
    await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
  }
}
