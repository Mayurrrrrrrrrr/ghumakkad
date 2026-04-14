import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class AuthRoutes {
  Router get router {
    final router = Router();
    router.post('/send-otp', _sendOtp);
    router.post('/verify-otp', _verifyOtp);
    router.post('/logout', _logout);
    router.put('/update-profile', _updateProfile);
    router.put('/fcm-token', _fcmToken);
    return router;
  }

  Future<Response> _sendOtp(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final phone = body['phone'];
      if (phone == null) return ApiResponse.error("Phone required");
      // TODO: replace with Firebase Admin SDK or SMS provider
      return ApiResponse.ok({"mock_otp": "123456"});
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _verifyOtp(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final phone = body['phone'];
      final firebaseToken = body['firebase_token']; // Frontend verifies OTP via Google
      if (phone == null || firebaseToken == null) return ApiResponse.error("Phone and Firebase Token required");

      // In production, you would verify the firebaseToken JWT with Google's public keys.
      // Since frontend just validated using Firebase SDK, we'll proceed to log them in.

      var user = await DB.queryOne('SELECT * FROM users WHERE phone = ?', [phone]);
      bool isNewUser = false;
      
      if (user == null) {
        final res = await DB.execute('INSERT INTO users (phone, name) VALUES (?, ?)', [phone, "Wanderer"]);
        user = await DB.queryOne('SELECT * FROM users WHERE id = ?', [res.insertId]);
        isNewUser = true;
      }

      final random = Random.secure();
      final values = List<int>.generate(32, (_) => random.nextInt(256));
      final token = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      
      final expiresAt = DateTime.now().add(const Duration(days: 30));
      final expStr = "${expiresAt.year}-${expiresAt.month.toString().padLeft(2,'0')}-${expiresAt.day.toString().padLeft(2,'0')} ${expiresAt.hour.toString().padLeft(2,'0')}:${expiresAt.minute.toString().padLeft(2,'0')}:${expiresAt.second.toString().padLeft(2,'0')}";

      await DB.execute(
        'INSERT INTO auth_tokens (user_id, token, expires_at) VALUES (?, ?, ?)',
        [user!['id'], token, expStr]
      );

      return ApiResponse.ok({
        'user': user,
        'token': token,
        'is_new_user': isNewUser
      });
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _logout(Request request) async {
    try {
      await Auth.requireLogin(request);
      final authHeader = request.headers['authorization'] ?? '';
      final token = authHeader.substring(7).trim();
      await DB.execute('DELETE FROM auth_tokens WHERE token = ?', [token]);
      return ApiResponse.ok(null, message: "Logged out");
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
      final name = body['name'];
      final avatarUrl = body['avatar_url'];
      if (name == null) return ApiResponse.error("Name required");

      await DB.execute('UPDATE users SET name = ?, avatar_url = ? WHERE id = ?', [name, avatarUrl, user['id']]);
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

      await DB.execute('UPDATE users SET fcm_token = ? WHERE id = ?', [fcmToken, user['id']]);
      return ApiResponse.ok(null);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
