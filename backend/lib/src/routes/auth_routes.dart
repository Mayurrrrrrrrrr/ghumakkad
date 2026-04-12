import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/db_service.dart';
import '../utils/response_helper.dart';
import 'package:crypto/crypto.dart';

class AuthRoutes {
  Router get router {
    final router = Router();

    // POST /api/v1/auth/send-otp
    router.post('/send-otp', (Request request) async {
      final body = await request.readAsString();
      print('Auth Routes: Body Length -> ${body.length}');
      print('Auth Routes: Body Content -> "$body"');

      if (body.isEmpty) {
        return ResponseHelper.error('Request body is empty');
      }

      final payload = jsonDecode(body);
      final phone = payload['phone'];

      if (phone == null || phone.toString().length < 10) {
        return ResponseHelper.error('Valid phone number is required');
      }

      // MOCK: In production, trigger OTP via SMS
      return ResponseHelper.success(
        {'phone': phone, 'mock_otp': '123456'},
        'OTP sent successfully',
      );
    });

    // POST /api/v1/auth/verify-otp
    router.post('/verify-otp', (Request request) async {
      final body = await request.readAsString();
      print('Auth Routes: Received Body (Verify) -> "$body"');

      if (body.isEmpty) {
        return ResponseHelper.error('Request body is empty');
      }

      final payload = jsonDecode(body);
      final phone = payload['phone'];
      final otp = payload['otp'];

      if (phone == null || otp == null) {
        return ResponseHelper.error('Phone and OTP are required');
      }

      if (otp != '123456') {
        return ResponseHelper.error('Invalid OTP');
      }

      final db = DbService().connection;
      
      // Check for user
      var result = await db.execute(
        'SELECT * FROM users WHERE phone = :phone',
        {'phone': phone},
      );

      bool isNew = false;
      var user;

      if (result.rows.isEmpty) {
        await db.execute(
          'INSERT INTO users (phone, name) VALUES (:phone, :name)',
          {'phone': phone, 'name': 'Wanderer'},
        );
        isNew = true;
        result = await db.execute(
          'SELECT * FROM users WHERE phone = :phone',
          {'phone': phone},
        );
      }
      
      user = result.rows.first.assoc();
      final userId = user['id'];

      // Generate token
      final token = sha256.convert(utf8.encode(DateTime.now().toString() + phone)).toString();
      final expiresAt = DateTime.now().add(const Duration(days: 30));

      await db.execute(
        'INSERT INTO auth_tokens (user_id, token, expires_at) VALUES (:u, :t, :e)',
        {
          'u': userId,
          't': token,
          'e': expiresAt.toIso8601String().replaceFirst('T', ' ').split('.').first,
        },
      );

      return ResponseHelper.success(
        {
          'user': user,
          'token': token,
          'is_new_user': isNew,
        },
        'Verified successfully',
      );
    });

    return router;
  }
}
