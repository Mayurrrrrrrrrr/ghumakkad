import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';

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

  Future<bool> sendOtp(String phone) async {
    return await _authService.sendOtp(phone);
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    final result = await _authService.verifyOtp(phone, otp);
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
