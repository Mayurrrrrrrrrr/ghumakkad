import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Verifies Firebase ID tokens (JWTs) issued by Firebase Authentication.
/// Fetches and caches Google's public RSA keys. Keys are rotated every few
/// hours by Google — we re-fetch when the cache expires.
class TokenVerifier {
  static const String _firebaseProjectId = 'ghumakkad-e2263';
  static const String _certsUrl =
      'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

  // In-memory cache: { kid -> RSAPublicKey PEM string }
  static Map<String, String> _keyCache = {};
  static DateTime _cacheExpiry = DateTime.fromMillisecondsSinceEpoch(0);

  /// Verifies the given Firebase ID token.
  /// Returns the decoded payload map on success.
  /// Throws [TokenVerificationException] with a clear message on any failure.
  static Future<Map<String, dynamic>> verify(String idToken) async {
    // Step 1: Decode header without verifying to extract key ID (kid)
    final parts = idToken.split('.');
    if (parts.length != 3) {
      throw TokenVerificationException('Malformed JWT: expected 3 parts');
    }

    Map<String, dynamic> header;
    try {
      final decoded = base64Url.decode(base64Url.normalize(parts[0]));
      header = jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
    } catch (_) {
      throw TokenVerificationException('Malformed JWT header');
    }

    final kid = header['kid'] as String?;
    if (kid == null) {
      throw TokenVerificationException('JWT header missing kid');
    }

    final alg = header['alg'] as String?;
    if (alg != 'RS256') {
      throw TokenVerificationException('JWT uses unsupported algorithm: $alg');
    }

    // Step 2: Fetch/cache public keys
    await _refreshKeysIfNeeded();

    final publicKeyPem = _keyCache[kid];
    if (publicKeyPem == null) {
      throw TokenVerificationException(
          'No public key found for kid=$kid. Token may be from a different project or already rotated.');
    }

    // Step 3: Verify signature and standard claims
    JWT jwt;
    try {
      jwt = JWT.verify(
        idToken,
        RSAPublicKey(publicKeyPem),
        checkHeaderType: false,
      );
    } on JWTExpiredException {
      throw TokenVerificationException('Firebase token has expired');
    } on JWTException catch (e) {
      throw TokenVerificationException('JWT verification failed: ${e.message}');
    } catch (e) {
      throw TokenVerificationException('JWT verification error: $e');
    }

    final payload = jwt.payload as Map<String, dynamic>;

    // Step 4: Validate Firebase-specific claims
    final aud = payload['aud'];
    if (aud != _firebaseProjectId) {
      throw TokenVerificationException(
          'JWT audience mismatch. Expected $_firebaseProjectId, got $aud');
    }

    final iss = payload['iss'] as String?;
    if (iss != 'https://securetoken.google.com/$_firebaseProjectId') {
      throw TokenVerificationException('JWT issuer mismatch: $iss');
    }

    final sub = payload['sub'] as String?;
    if (sub == null || sub.isEmpty) {
      throw TokenVerificationException('JWT missing sub claim');
    }

    // Step 5: Extract phone number from token (do NOT trust phone from request body)
    final phone = payload['phone_number'] as String?;
    if (phone == null || phone.isEmpty) {
      throw TokenVerificationException(
          'JWT missing phone_number claim. User may not have authenticated via phone.');
    }

    return payload;
  }

  static Future<void> _refreshKeysIfNeeded() async {
    if (DateTime.now().isBefore(_cacheExpiry) && _keyCache.isNotEmpty) {
      return; // Cache still valid
    }

    final response = await http.get(Uri.parse(_certsUrl));
    if (response.statusCode != 200) {
      throw TokenVerificationException(
          'Failed to fetch Google public keys. HTTP ${response.statusCode}');
    }

    // Parse Cache-Control header to determine expiry
    // e.g. "public, max-age=19894, must-revalidate, no-transform"
    int maxAgeSeconds = 3600; // default 1 hour if header missing
    final cacheControl = response.headers['cache-control'] ?? '';
    final maxAgeMatch = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
    if (maxAgeMatch != null) {
      maxAgeSeconds = int.tryParse(maxAgeMatch.group(1) ?? '') ?? 3600;
    }

    _keyCache = Map<String, String>.from(
        jsonDecode(response.body) as Map<String, dynamic>);
    _cacheExpiry = DateTime.now().add(Duration(seconds: maxAgeSeconds));
  }
}

class TokenVerificationException implements Exception {
  final String message;
  TokenVerificationException(this.message);

  @override
  String toString() => 'TokenVerificationException: $message';
}
