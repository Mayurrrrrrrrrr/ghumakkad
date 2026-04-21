# Ghumakkad — Production Auth Finalization Prompt
**Agent:** Cursor / Windsurf / Claude Code  
**Project root:** `/home/ubuntu/ghumakkad/` (on server) or your local clone of `https://github.com/Mayurrrrrrrrrr/ghumakkad.git`

---

## Context (read before doing anything)

This is a Flutter + Dart Shelf backend app called **Ghumakkad** (trip companion). Firebase billing has just been activated, which enables real Phone Authentication via Firebase Identity Platform.

Current state of the codebase:
- `backend/lib/src/routes/auth_routes.dart` — has a `/send-otp` route that returns `{"mock_otp": "123456"}` (hardcoded, insecure), and a `/verify-otp` route that accepts `firebase_token` but **does NOT actually verify it** — it blindly trusts the `phone` field from the request body instead.
- `frontend/lib/core/services/auth_service.dart` — already correct. Uses `FirebaseAuth.instance.verifyPhoneNumber()` and `signInWithCredential()`. No changes needed here.
- `backend/pubspec.yaml` — currently only has: `shelf`, `shelf_router`, `mysql_client`, `crypto`, `mime`, `path`, `intl`. Missing HTTP and JWT packages.
- Firebase project ID is: `ghumakkad-e2263`
- Production domain: `https://ghumakkad.yuktaa.com`
- Backend runs as compiled Dart binary via PM2. Entry point: `backend/bin/server.dart`
- DB schema: `users` table has columns `id, phone, name, avatar_url, fcm_token, is_active, created_at, updated_at`. The `auth_tokens` table has `id, user_id, token, expires_at, created_at`.

---

## Exact changes required

### CHANGE 1 — `backend/pubspec.yaml`

Add two packages under `dependencies`. The final `dependencies` block must look exactly like this:

```yaml
dependencies:
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  mysql_client: ^0.0.27
  crypto: ^3.0.3
  mime: ^1.0.4
  path: ^1.9.0
  intl: ^0.19.0
  http: ^1.2.0
  dart_jsonwebtoken: ^2.14.0
```

Do NOT add any other packages. Do NOT change versions of existing packages.

---

### CHANGE 2 — Create new file `backend/lib/src/core/token_verifier.dart`

Create this file with exactly the following content. Do not modify the logic:

```dart
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
```

---

### CHANGE 3 — Rewrite `backend/lib/src/routes/auth_routes.dart`

Replace the **entire file** with the following. Key changes:
- `/send-otp` route is **completely removed** (delete the route registration AND the `_sendOtp` method)
- `/verify-otp` now calls `TokenVerifier.verify()` first, then extracts `phone_number` from the verified JWT payload — it does NOT use the phone from the request body
- Import `token_verifier.dart`

```dart
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
```

---

### CHANGE 4 — `frontend/lib/core/constants/api_constants.dart`

Remove the `sendOtp` constant since that route no longer exists. Replace the auth section:

```dart
// Auth
// sendOtp removed — Firebase SDK handles SMS directly, no backend route needed
static const String verifyOtp = '/auth/verify-otp';
static const String logout = '/auth/logout';
static const String updateProfile = '/auth/update-profile';
static const String fcmToken = '/auth/fcm-token';
```

Keep all other constants unchanged.

---

### CHANGE 5 — `deployment/deploy.sh`

Update the test command at the bottom to remove the obsolete `send-otp` test. Replace the last `echo` line with:

```bash
echo "Test backend health: curl https://ghumakkad.yuktaa.com/api/v1/trips/ -H 'Authorization: Bearer YOUR_TOKEN'"
echo "To test auth: use a real Firebase ID token from a test device or Firebase test phone number"
```

---

### CHANGE 6 — Frontend build (run this command)

After all file changes above are saved, run from the `frontend/` directory:

```bash
flutter build web --release
```

If this fails, check `analyze.txt` or run `flutter analyze` first. Do not proceed to git steps if build fails.

---

### CHANGE 7 — Git commit and push

After the build succeeds, run from the project root:

```bash
git add backend/pubspec.yaml
git add backend/lib/src/core/token_verifier.dart
git add backend/lib/src/routes/auth_routes.dart
git add frontend/lib/core/constants/api_constants.dart
git add deployment/deploy.sh
git add frontend/build/web/
git commit -m "chore: finalize production auth after billing activation

- Add real Firebase JWT verification via dart_jsonwebtoken + http packages
- Create TokenVerifier service with Google public key caching (respects Cache-Control TTL)
- Phone number now extracted from verified JWT payload, not from request body
- Remove /send-otp mock route entirely (Firebase SDK handles SMS on client)
- Remove mock_otp response from backend
- Update deploy.sh test instructions
- Production web build included"
git push origin main
```

---

## Verification steps (do these after deploy)

### Step A — Confirm backend compiles with new packages

```bash
cd backend
dart pub get
dart compile exe bin/server.dart -o ghumakkad_server_test
```

Expected: no errors. If you see `dart_jsonwebtoken` not found, run `dart pub get` again.

### Step B — Test that invalid token is rejected

```bash
curl -s -X POST https://ghumakkad.yuktaa.com/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"firebase_token": "not.a.real.token"}' | python3 -m json.tool
```

Expected response:
```json
{
  "success": false,
  "data": null,
  "message": "Invalid or expired Firebase token"
}
```

### Step C — Confirm /send-otp is gone (returns 404, not mock OTP)

```bash
curl -s -X POST https://ghumakkad.yuktaa.com/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "9999999999"}'
```

Expected: 404 response. If it still returns `{"mock_otp":"123456"}`, the backend has not been redeployed — run `pm2 restart ghumakkad-api`.

### Step D — End-to-end test with a real device

Use a real Android device or Firebase test phone number:
1. Open app, enter phone number
2. Receive SMS OTP (now real, not mock — billing is active)
3. Enter OTP
4. App should log in successfully and reach home screen
5. Check your MySQL `users` table — new row should exist with correct phone

---

## Do NOT change

- `frontend/lib/core/services/auth_service.dart` — already production-ready, do not touch
- `backend/lib/src/core/auth.dart` — session token verification logic is correct, do not touch
- `backend/lib/src/core/db.dart` — no changes needed
- `frontend/lib/firebase_options.dart` — already configured for project `ghumakkad-e2263`
- Any other route files (`trip_routes.dart`, `pin_routes.dart`, etc.) — not affected
- `backend/config/database.dart` — your real credentials are already there (this file is gitignored)

---

## Common failure modes and fixes

| Problem | Cause | Fix |
|---|---|---|
| `dart_jsonwebtoken` package not found | `dart pub get` not run after pubspec change | Run `dart pub get` in `backend/` |
| `TokenVerificationException: No public key found for kid=...` | Google rotated keys since last cache | This is transient — keys will refresh automatically on next request. If persistent, check network connectivity from server to `googleapis.com` |
| `JWT audience mismatch` | Wrong project ID in token_verifier.dart | Confirm Firebase project ID is exactly `ghumakkad-e2263` in Firebase Console |
| `JWT missing phone_number claim` | User authenticated via email/Google, not phone | Only phone auth tokens contain `phone_number` — ensure app is using `verifyPhoneNumber()` flow |
| Build web fails | Flutter/Dart version mismatch | Run `flutter doctor` and ensure Flutter SDK matches `sdk: ^3.11.4` in pubspec |
| `/verify-otp` returns 500 after deploy | DB connection dropped after PM2 restart | Run `pm2 logs ghumakkad-api` to see error. If DB disconnected, `pm2 restart ghumakkad-api` |
