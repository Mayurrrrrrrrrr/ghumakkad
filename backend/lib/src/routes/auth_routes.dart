import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';
import '../core/token_verifier.dart';

class AuthRoutes {
  Router get router {
    final router = Router();
    // NOTE: /send-otp is intentionally removed.
    // Firebase SDK handles SMS delivery directly on the client.
    // If you need test phone numbers, use Firebase Console →
    // Authentication → Sign-in method → Phone → Test phone numbers.
    router.post('/verify-otp', _verifyOtp);
    router.post('/logout', _logout);
    router.put('/update-profile', _updateProfile);
    router.put('/fcm-token', _fcmToken);
    return router;
  }

  Future<Response> _verifyOtp(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final firebaseToken = body['firebase_token'] as String?;

      if (firebaseToken == null || firebaseToken.isEmpty) {
        return ApiResponse.error('firebase_token is required');
      }

      // Step 1: Verify the Firebase ID token cryptographically.
      // This fetches Google's public keys and validates signature + claims.
      // Phone number is extracted from the VERIFIED token — never from request body.
      Map<String, dynamic> tokenPayload;
      try {
        tokenPayload = await TokenVerifier.verify(firebaseToken);
      } on TokenVerificationException catch (e) {
        print('[AuthRoutes] Token verification failed: ${e.message}');
        return ApiResponse.unauthorized('Invalid or expired Firebase token');
      }

      // Extract phone from verified JWT payload (format: "+919876543210")
      final phoneWithCode = tokenPayload['phone_number'] as String;
      // Store phone without country code ("+91XXXXXXXXXX" → "XXXXXXXXXX")
      // Adjust this logic if you store full international format.
      final phone = phoneWithCode.startsWith('+91')
          ? phoneWithCode.substring(3)
          : phoneWithCode;

      // Step 2: Find existing user or create new one
      var user = await DB.queryOne('SELECT * FROM users WHERE phone = ?', [phone]);
      bool isNewUser = false;

      if (user == null) {
        final res = await DB.execute(
          'INSERT INTO users (phone, name) VALUES (?, ?)',
          [phone, 'Wanderer'],
        );
        user = await DB.queryOne('SELECT * FROM users WHERE id = ?', [res.insertId]);
        isNewUser = true;
      }

      // Step 3: Generate a secure random session token (64 hex chars = 256 bits)
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      final sessionToken = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      // Step 4: Store session token in DB (valid for 30 days)
      final expiresAt = DateTime.now().add(const Duration(days: 30));
      final expStr =
          '${expiresAt.year}-${expiresAt.month.toString().padLeft(2, '0')}-${expiresAt.day.toString().padLeft(2, '0')} '
          '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}:${expiresAt.second.toString().padLeft(2, '0')}';

      await DB.execute(
        'INSERT INTO auth_tokens (user_id, token, expires_at) VALUES (?, ?, ?)',
        [user!['id'], sessionToken, expStr],
      );

      return ApiResponse.ok({
        'user': user,
        'token': sessionToken,
        'is_new_user': isNewUser,
      });
    } catch (e) {
      print('[AuthRoutes] _verifyOtp unexpected error: $e');
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _logout(Request request) async {
    try {
      await Auth.requireLogin(request);
      final authHeader = request.headers['authorization'] ?? '';
      final token = authHeader.substring(7).trim();
      await DB.execute('DELETE FROM auth_tokens WHERE token = ?', [token]);
      return ApiResponse.ok(null, message: 'Logged out');
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _updateProfile(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['name'] as String?;
      final avatarUrl = body['avatar_url'];
      if (name == null || name.trim().isEmpty) {
        return ApiResponse.error('name is required');
      }
      await DB.execute(
        'UPDATE users SET name = ?, avatar_url = ? WHERE id = ?',
        [name.trim(), avatarUrl, user['id']],
      );
      final updatedUser = await DB.queryOne('SELECT * FROM users WHERE id = ?', [user['id']]);
      return ApiResponse.ok(updatedUser);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _fcmToken(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final fcmToken = body['fcm_token'];
      await DB.execute(
        'UPDATE users SET fcm_token = ? WHERE id = ?',
        [fcmToken, user['id']],
      );
      return ApiResponse.ok(null);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
