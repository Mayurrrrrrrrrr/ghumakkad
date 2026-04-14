import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthService(this._apiService);

  Future<void> sendOtp({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<Map<String, dynamic>?> verifyOtp({
    required String verificationId,
    required String otp,
    required String phone,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) return null;

      // Exchange Firebase Token with backend
      final response = await _apiService.post(ApiConstants.verifyOtp, data: {
        'phone': phone,
        'firebase_token': idToken,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];
        final user = data['user'];
        final isNew = data['is_new_user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_data', json.encode(user));

        return {
          'user': user,
          'isNew': isNew,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _apiService.post(ApiConstants.logout);
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }
}

