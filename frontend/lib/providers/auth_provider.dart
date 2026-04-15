import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';

Future<int?> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userDataStr = prefs.getString('user_data');
  if (userDataStr == null) return null;
  final userData = json.decode(userDataStr);
  return userData['id'] as int?;
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return AuthService(apiService);
});

enum AuthState { initial, authenticated, unauthenticated, onboarding }

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial) {
    checkAuth();
  }



  Future<void> checkAuth() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> sendOtp({
    required String phone,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    await _authService.sendOtp(
      phone: phone,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  Future<bool> verifyOtp(String phone, String verificationId, String otp) async {
    final result = await _authService.verifyOtp(
      verificationId: verificationId,
      otp: otp,
      phone: phone,
    );
    if (result != null) {
      if (result['isNew'] == true) {
        state = AuthState.onboarding;
      } else {
        state = AuthState.authenticated;
      }
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});
