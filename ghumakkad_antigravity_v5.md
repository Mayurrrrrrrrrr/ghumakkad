# GHUMAKKAD — Status Report + Antigravity Prompt v5.0
### Full code review — April 2026

---

# PART 1 — CURRENT STATUS

## Overall Progress: ~88% Complete ✅

The project has made excellent progress since v4. Most backend routes exist,
all Flutter screens are built, Firebase is partially configured. What remains
is fixing specific bugs — not building new features.

---

## WHAT'S FIXED SINCE LAST REVIEW ✅
- `main.dart` now imports `firebase_options.dart` and uses `DefaultFirebaseOptions` ✅
- `google-services.json` is present in `android/app/` ✅
- `build.gradle.kts` has `com.google.gms.google-services` plugin ✅
- `settings.gradle.kts` has `com.google.gms.google-services:4.4.2` ✅
- All Android permissions added to `AndroidManifest.xml` ✅
- `profile_setup_screen.dart` now calls `PUT /auth/update-profile` ✅
- `trips_provider.dart` handles both array and `{trips:[]}` response formats ✅
- Home screen wired to real `tripsProvider` ✅

---

## FIREBASE PROBLEMS — ROOT CAUSE ANALYSIS

### 🔴 Problem 1: `firebase_options.dart` IS MISSING FROM REPO

`main.dart` imports it:
```dart
import 'firebase_options.dart';  // ← this file does NOT exist in repo
```

The file is gitignored (correct) but it must exist on the build machine.
`google-services.json` is present but `firebase_options.dart` is NOT generated yet.

**This is why the app crashes on launch** — Dart can't compile because the
import doesn't resolve.

**Fix — run this ONCE on your dev machine:**
```bash
cd frontend/

# Install flutterfire CLI if not done:
dart pub global activate flutterfire_cli

# Configure (select your project ghumakkad-e2263):
flutterfire configure --project=ghumakkad-e2263

# This generates: frontend/lib/firebase_options.dart
# Keep it gitignored but check it into your local machine
```

---

### 🔴 Problem 2: `oauth_client` array is EMPTY in google-services.json

From the file:
```json
"oauth_client": [],   ← EMPTY — no SHA-1 registered
```

Firebase Phone Auth on Android requires the debug SHA-1 fingerprint
to be registered in the Firebase Console. Without it:
- `verifyPhoneNumber()` is called
- Firebase silently fails or shows "Blocked" error
- No OTP is ever sent
- No error is thrown — just timeout

**Fix — 3 steps:**

Step 1 — Get your SHA-1:
```bash
cd frontend/android
./gradlew signingReport
# Look for "Variant: debug" section
# Copy the SHA-1 line (looks like: AB:CD:12:34:...)
```

Step 2 — Register in Firebase Console:
- Go to: https://console.firebase.google.com
- Select project: `ghumakkad-e2263`
- Project Settings → Your Apps → Android app (`in.ghumakkad.app`)
- Click "Add fingerprint"
- Paste the SHA-1
- Save

Step 3 — Re-download google-services.json:
- In the same Firebase Console page, click "Download google-services.json"
- Replace `frontend/android/app/google-services.json` with the new file
- Re-run `flutterfire configure` to regenerate `firebase_options.dart`

---

### 🔴 Problem 3: Nginx proxy strips `/api/` — ALL API CALLS RETURN 404

**This is unfixed from v4.** The Nginx config still has:
```nginx
location /api/ {
    proxy_pass http://localhost:8080/;   ← WRONG — trailing slash strips /api/
}
```

A Flutter request to `https://ghumakkad.yuktaa.com/api/v1/trips/` arrives
at Nginx as `/api/v1/trips/`. Nginx strips `/api/` and forwards `/v1/trips/`
to the Dart server. But the Dart server's router is mounted at `/api/v1/trips/`.
So every single API call returns 404.

**Fix on server:**
```bash
sudo nano /etc/nginx/sites-available/ghumakkad
```
Change:
```nginx
proxy_pass http://localhost:8080/;
```
To:
```nginx
proxy_pass http://localhost:8080/api/;
```
Then:
```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

### 🟡 Problem 4: `auth_provider.dart` has a DART COMPILE ERROR

Imports appear AFTER a function definition — Dart requires all imports
at the top of the file before any code:

```dart
// CURRENT (broken — imports after function):
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<int?> getCurrentUserId() async { ... }   // ← CODE BEFORE IMPORTS BELOW

import '../core/services/api_service.dart';       // ← ILLEGAL IN DART
import '../core/services/auth_service.dart';      // ← ILLEGAL IN DART
```

This causes a compile error. Fix by moving all imports to the top.

---

### 🟡 Problem 5: `android:label="app"` — wrong app name

In `AndroidManifest.xml`:
```xml
android:label="app"   ← shows "app" on the phone, should be "Ghumakkad"
```
Change to:
```xml
android:label="Ghumakkad"
```

---

### 🟡 Problem 6: `minSdk = flutter.minSdkVersion` is too low

`flutter.minSdkVersion` defaults to 16. Firebase Phone Auth requires minSdk 19+.
Firebase Auth 6.x actually requires minSdk 21+.

Fix in `frontend/android/app/build.gradle.kts`:
```kotlin
minSdk = 21   // ← change from flutter.minSdkVersion
```

---

### 🟡 Problem 7: `verifyOtp` silently swallows errors

In `auth_service.dart`:
```dart
} catch (e) {
  return null;  // ← hides ALL errors, user just sees "Invalid OTP"
}
```

When Firebase OTP verification fails, the real error (token expired,
wrong code, network error, SHA-1 not registered) is completely hidden.
This makes debugging impossible.

**Fix — print the error at minimum during development:**
```dart
} catch (e) {
  print('verifyOtp error: $e');  // ADD THIS
  return null;
}
```

---

### 🟡 Problem 8: No test phone numbers set up in Firebase

During development, Firebase blocks real SMS to random numbers unless
you set up test phone numbers in the console.

**Fix:**
- Firebase Console → Authentication → Sign-in method → Phone
- Scroll to "Phone numbers for testing"
- Add: `+91 9999999999` → Code: `123456`
- This lets you test without real SMS

---

### 🟡 Problem 9: Backend `database.dart` — is it on the server?

`backend/lib/src/config/` only has `database.dart.example` in the repo.
The real `database.dart` must exist on the server at:
`/home/ubuntu/ghumakkad/backend/lib/src/config/database.dart`

If it was deleted when cleaning up credentials, the Dart server won't compile.

**Verify on server:**
```bash
cat /home/ubuntu/ghumakkad/backend/lib/src/config/database.dart
# If missing, create from example:
cp /home/ubuntu/ghumakkad/backend/lib/src/config/database.dart.example \
   /home/ubuntu/ghumakkad/backend/lib/src/config/database.dart
nano /home/ubuntu/ghumakkad/backend/lib/src/config/database.dart
# Fill in real credentials
```

---

## OTHER CODE ISSUES FOUND

### Backend: `expense_routes.dart` — `_create` is incomplete
The split logic (equal/custom/individual) from v4 prompt was not implemented.
The method exists but is missing the `expense_splits` INSERT logic.

### Backend: Several route files likely still scaffold-level
`memory_routes.dart`, `ticket_routes.dart`, `hotel_routes.dart` need verification.

### Frontend: `share_plus: 12.0.2` — missing `^` caret
```yaml
share_plus: 12.0.2    ← exact version pin, may cause pub get issues
# Should be:
share_plus: ^12.0.2
```

### Frontend: `members_provider.dart` — needs verification it's wired
The `add_expense_screen.dart` needs members list for "paid by" dropdown.

---

# PART 2 — ANTIGRAVITY PROMPT v5.0

---

## PROJECT CONTEXT

**Ghumakkad** (घुमक्कड़) — Flutter + Dart backend trip memory app.

**Repo:** `https://github.com/Mayurrrrrrrrrr/ghumakkad`
**Server:** `92.4.84.229` | Nginx → PM2 → Dart binary port 8080
**Firebase project:** `ghumakkad-e2263` | Project number: `512259810344`
**Android package:** `in.ghumakkad.app`
**API base URL:** `https://ghumakkad.yuktaa.com/api/v1`

Stack: Flutter + Riverpod + Dio | Dart shelf backend | MySQL 8 | Firebase Phone Auth

The project is ~88% complete. Only fix the specific bugs below.
Do NOT rewrite working code.

---

## FIX 1 — `frontend/lib/providers/auth_provider.dart` (COMPILE ERROR)

Rewrite the top of this file. All imports must come before any code:

```dart
// auth_provider.dart — CORRECT VERSION
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';

// Helper function — AFTER imports
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
```

---

## FIX 2 — `frontend/lib/core/services/auth_service.dart` (add error logging)

In `verifyOtp`, expose the error instead of swallowing it silently:

```dart
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

    if (idToken == null) {
      print('[AuthService] Firebase sign-in succeeded but idToken is null');
      return null;
    }

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

      return {'user': user, 'isNew': isNew};
    }
    print('[AuthService] Backend verify-otp failed: ${response.data}');
    return null;
  } on FirebaseAuthException catch (e) {
    print('[AuthService] FirebaseAuthException: ${e.code} — ${e.message}');
    return null;
  } catch (e) {
    print('[AuthService] verifyOtp error: $e');
    return null;
  }
}
```

Also update `sendOtp` to log errors:
```dart
verificationFailed: (FirebaseAuthException e) {
  print('[AuthService] verificationFailed: ${e.code} — ${e.message}');
  onError(e.message ?? 'Verification failed');
},
```

---

## FIX 3 — `frontend/android/app/src/main/AndroidManifest.xml`

Change app label:
```xml
android:label="Ghumakkad"   <!-- was: android:label="app" -->
```

---

## FIX 4 — `frontend/android/app/build.gradle.kts`

Set explicit minSdk:
```kotlin
defaultConfig {
    applicationId = "in.ghumakkad.app"
    minSdk = 21            // ← change from flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

---

## FIX 5 — `frontend/pubspec.yaml`

Fix share_plus version pin:
```yaml
share_plus: ^12.0.2   # ← add the ^ caret
```

---

## FIX 6 — `ghumakkad.conf` (Nginx — fix on server)

**This fix must be done directly on the server, not just in the repo.**

Change proxy_pass to preserve the `/api/` prefix:
```nginx
location /api/ {
    proxy_pass http://localhost:8080/api/;   # ← was: http://localhost:8080/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 10M;
    # Remove these two lines (they're for WebSocket, not needed for REST):
    # proxy_set_header Upgrade $http_upgrade;
    # proxy_set_header Connection 'upgrade';
}
```

Apply on server:
```bash
sudo cp /home/ubuntu/ghumakkad/ghumakkad.conf /etc/nginx/sites-available/ghumakkad
sudo nginx -t
sudo systemctl reload nginx
```

---

## FIX 7 — `backend/lib/src/routes/expense_routes.dart` (complete _create)

The `_create` method is missing the `expense_splits` INSERT logic.
After `INSERT INTO trip_expenses`, add:

```dart
newExpenseId = res.insertId;

if (splitType == 'equal') {
  List<dynamic> memberIds;
  if (body['split_among'] != null) {
    memberIds = body['split_among'] as List;
  } else {
    final allMembers = await DB.query(
      'SELECT user_id FROM trip_members WHERE trip_id = ?', [tripId]
    );
    memberIds = allMembers.map((m) => m['user_id']).toList();
  }

  final shareRaw = amount / memberIds.length;
  final share = double.parse(shareRaw.toStringAsFixed(2));
  final remainder = double.parse(
    (amount - share * memberIds.length).toStringAsFixed(2)
  );

  for (int i = 0; i < memberIds.length; i++) {
    final memberShare = (i == 0) ? share + remainder : share;
    await DB.execute(
      'INSERT INTO expense_splits (expense_id, user_id, share_amount) VALUES (?, ?, ?)',
      [newExpenseId, memberIds[i], memberShare]
    );
  }

} else if (splitType == 'custom') {
  final customSplits = body['custom_splits'] as List;
  for (final split in customSplits) {
    await DB.execute(
      'INSERT INTO expense_splits (expense_id, user_id, share_amount) VALUES (?, ?, ?)',
      [newExpenseId, split['user_id'], split['amount']]
    );
  }

} else if (splitType == 'individual') {
  await DB.execute(
    'INSERT INTO expense_splits (expense_id, user_id, share_amount) VALUES (?, ?, ?)',
    [newExpenseId, body['individual_user_id'], amount]
  );
}
```

---

## FIX 8 — `backend/lib/src/routes/trip_routes.dart` (wrap list response)

In `_list`, wrap trips array so frontend key works:
```dart
// CHANGE:
return ApiResponse.ok(trips);
// TO:
return ApiResponse.ok({'trips': trips});
```

---

## FIX 9 — `backend/lib/src/routes/pin_routes.dart` (add added_by)

In `_create`, the INSERT is missing `added_by`:
```dart
// CHANGE:
final res = await DB.execute('''
  INSERT INTO trip_pins (trip_id, pin_type, title, latitude, longitude, address, pinned_at)
  VALUES (?, ?, ?, ?, ?, ?, ?)
''', [tripId, body['pin_type'] ?? 'waypoint', ...]);

// TO:
final res = await DB.execute('''
  INSERT INTO trip_pins (trip_id, added_by, pin_type, title, latitude, longitude, address, pinned_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''', [
  tripId,
  user['id'],    // ← ADD THIS
  body['pin_type'] ?? 'memory',
  body['title'],
  body['latitude'],
  body['longitude'],
  body['address'],
  body['pinned_at'] ?? DateTime.now().toIso8601String(),
]);
```

---

## FIX 10 — Complete these backend route files if they are scaffold-only

Check each file. If any handler just returns a placeholder or empty response,
complete it following the pattern in `trip_routes.dart`.

### `memory_routes.dart` — must have 4 working handlers:

```
GET  /?pin_id=X    → query pin_memories JOIN users WHERE pin_id=?
POST /             → INSERT pin_memories (pin_id, added_by=user.id, memory_type, content, caption)
DELETE /<id>       → DELETE WHERE id=? AND added_by=user.id (own memories only)
GET  /trip/<tripId>→ SELECT pm.*, tp.title as pin_title, tp.latitude, tp.longitude,
                              tp.pinned_at, u.name as added_by_name, u.avatar_url
                     FROM pin_memories pm
                     JOIN trip_pins tp ON pm.pin_id = tp.id
                     JOIN users u ON pm.added_by = u.id
                     WHERE tp.trip_id = ?
                     ORDER BY tp.pinned_at ASC, pm.created_at ASC
```

### `ticket_routes.dart` — must have 4 working handlers:
```
GET  /?trip_id=X  → SELECT * FROM trip_tickets WHERE trip_id=? (member check first)
POST /            → INSERT trip_tickets (trip_id, added_by=user.id, all fields)
PUT  /<id>        → UPDATE (added_by=user.id OR user is creator)
DELETE /<id>      → DELETE (added_by=user.id OR user is creator)
```

### `hotel_routes.dart` — same pattern as tickets:
```
GET  /?trip_id=X  → SELECT * FROM trip_hotels WHERE trip_id=?
POST /            → INSERT trip_hotels (trip_id, added_by=user.id, all fields)
PUT  /<id>        → UPDATE (added_by OR creator)
DELETE /<id>      → DELETE (added_by OR creator)
```

### `member_routes.dart`:
```
GET  /?trip_id=X  → SELECT u.id, u.name, u.avatar_url, u.phone, tm.role
                    FROM trip_members tm JOIN users u ON tm.user_id=u.id
                    WHERE tm.trip_id=?
DELETE /          → body: {trip_id, user_id}
                    Check: requesting user is creator
                    Check: cannot remove yourself
                    DELETE FROM trip_members WHERE trip_id=? AND user_id=?
```

### `hisaab_routes.dart`:
```
GET  /<tripId>         → calls HisaabService.calculateSettlement(tripId)
                         returns {settlements, per_member_summary, trip_total}
POST /<tripId>/settle  → body: {expense_split_id}
                         UPDATE expense_splits SET is_settled=1, settled_at=NOW()
                         WHERE id=? (verify split belongs to this trip first)
```

### `upload_routes.dart` — multipart image upload:
```dart
// POST /image
// Parse multipart/form-data, field: 'image'
// Validate: image/jpeg | image/png | image/webp only, max 5MB
// Save to: /var/www/ghumakkad/uploads/{year}/{month}/{randomHex8}.{ext}
// Return: { url: 'https://ghumakkad.yuktaa.com/uploads/{year}/{month}/{file}' }

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:mime/mime.dart';

Future<Response> _uploadImage(Request request) async {
  try {
    final user = await Auth.requireLogin(request);
    final contentType = request.headers['content-type'] ?? '';
    if (!contentType.contains('multipart/form-data')) {
      return ApiResponse.error('multipart/form-data required');
    }
    final boundary = contentType.split('boundary=').last.trim();
    final allBytes = await request.read().expand((x) => x).toList();
    final stream = Stream.fromIterable([Uint8List.fromList(allBytes)]);
    final parts = stream.transform(MimeMultipartTransformer(boundary));

    Uint8List? fileBytes;
    String mimeType = 'image/jpeg';

    await for (final part in parts) {
      final disp = part.headers['content-disposition'] ?? '';
      if (disp.contains('name="image"')) {
        mimeType = part.headers['content-type'] ?? 'image/jpeg';
        final bytes = await part.expand((x) => x).toList();
        fileBytes = Uint8List.fromList(bytes);
      }
    }

    if (fileBytes == null) return ApiResponse.error('No image provided');
    if (!['image/jpeg','image/png','image/webp'].contains(mimeType)) {
      return ApiResponse.error('Only JPG, PNG, WebP allowed');
    }
    if (fileBytes.length > 5 * 1024 * 1024) {
      return ApiResponse.error('Max file size is 5MB');
    }

    final ext = mimeType == 'image/png' ? 'png' : mimeType == 'image/webp' ? 'webp' : 'jpg';
    final now = DateTime.now();
    final ym = '${now.year}/${now.month.toString().padLeft(2,'0')}';
    final dir = Directory('/var/www/ghumakkad/uploads/$ym');
    await dir.create(recursive: true);

    final rng = Random.secure();
    final nameHex = List.generate(8, (_) => rng.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2,'0')).join();
    final filename = '$nameHex.$ext';

    await File('${dir.path}/$filename').writeAsBytes(fileBytes);
    final url = 'https://ghumakkad.yuktaa.com/uploads/$ym/$filename';
    return ApiResponse.ok({'url': url});

  } on UnauthorizedException {
    return ApiResponse.unauthorized();
  } catch (e) {
    return ApiResponse.serverError(e.toString());
  }
}
```

---

## FIX 11 — `frontend/lib/screens/trip/add_pin_screen.dart` (wire photo upload)

Replace placeholder photo box with real picker + upload:

```dart
// Add imports:
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

// Add to state:
XFile? _selectedImage;
String? _uploadedImageUrl;
bool _isUploading = false;

// Replace placeholder Container with:
GestureDetector(
  onTap: _pickAndUploadImage,
  child: Container(
    height: 120,
    width: 120,
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
    ),
    child: _isUploading
      ? const Center(child: CircularProgressIndicator())
      : _selectedImage != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
          )
        : const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
  ),
)

// Add method:
Future<void> _pickAndUploadImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  if (image == null) return;
  setState(() { _selectedImage = image; _isUploading = true; });
  try {
    final apiService = ref.read(apiServiceProvider);
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    final response = await apiService.client.post('/upload/image', data: formData);
    if (response.data['success'] == true) {
      _uploadedImageUrl = response.data['data']['url'];
    }
  } catch (e) {
    print('Image upload error: $e');
  } finally {
    setState(() => _isUploading = false);
  }
}

// In _savePin(), after successful pin save, also post memory if image present:
if (_uploadedImageUrl != null) {
  try {
    final apiService = ref.read(apiServiceProvider);
    await apiService.post('/memories', data: {
      'pin_id': newPinId,   // get from addPin response
      'memory_type': 'photo',
      'content': _uploadedImageUrl,
      'caption': _titleController.text,
    });
  } catch (e) { /* non-fatal */ }
}
```

---

## FIX 12 — `frontend/lib/screens/trip/settlement_screen.dart` (UPI links)

Add url_launcher UPI deep link:

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> _openUpi(settlement) async {
  final amount = settlement.amount.toStringAsFixed(2);
  final note = Uri.encodeComponent('Ghumakkad: ${trip.title}');
  final upiUri = Uri.parse('upi://pay?am=$amount&cu=INR&tn=$note');

  if (await canLaunchUrl(upiUri)) {
    await launchUrl(upiUri, mode: LaunchMode.externalApplication);
  } else {
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pay Amount'),
          content: Text(
            'Pay ₹${settlement.amount.toStringAsFixed(2)} to ${settlement.toUser['name']}\n\nOpen GPay, PhonePe, or Paytm manually.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        ),
      );
    }
  }
}
```

---

## FIX 13 — `frontend/lib/screens/trip/members_screen.dart` (invite QR + share)

```dart
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

// In invite section widget:
Column(
  children: [
    QrImageView(
      data: 'https://ghumakkad.yuktaa.com/join/${trip.inviteCode}',
      version: QrVersions.auto,
      size: 180.0,
      backgroundColor: Colors.white,
    ),
    const SizedBox(height: 16),
    Text(
      trip.inviteCode,
      style: AppTypography.heading.copyWith(
        letterSpacing: 4, fontSize: 20, color: AppColors.primary,
      ),
    ),
    const SizedBox(height: 16),
    ElevatedButton.icon(
      onPressed: () => Share.share(
        'Join my trip "${trip.title}" on Ghumakkad!\n'
        'https://ghumakkad.yuktaa.com/join/${trip.inviteCode}'
      ),
      icon: const Icon(Icons.share),
      label: const Text('Share Invite'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  ],
)
```

---

## FIREBASE SETUP CHECKLIST (Manual steps — cannot be automated by AI agent)

These must be done BY YOU manually before any code fix will work for Firebase:

```
⬜ 1. Run: cd frontend && flutterfire configure --project=ghumakkad-e2263
       → generates: frontend/lib/firebase_options.dart

⬜ 2. Get SHA-1:  cd frontend/android && ./gradlew signingReport
       → copy SHA-1 from "Variant: debug" output

⬜ 3. Firebase Console → ghumakkad-e2263 → Project Settings
       → Android app (in.ghumakkad.app) → Add fingerprint → paste SHA-1 → Save

⬜ 4. Re-download google-services.json from Firebase Console
       → replace frontend/android/app/google-services.json

⬜ 5. Firebase Console → Authentication → Sign-in method → Phone → Enable
       (if not already enabled)

⬜ 6. Firebase Console → Authentication → Sign-in method → Phone
       → Phone numbers for testing → Add: +91 9999999999 → Code: 123456

⬜ 7. On server: fix Nginx proxy_pass
       sudo nano /etc/nginx/sites-available/ghumakkad
       change: proxy_pass http://localhost:8080/;
       to:     proxy_pass http://localhost:8080/api/;
       then:   sudo nginx -t && sudo systemctl reload nginx

⬜ 8. On server: verify database.dart exists with real credentials
       cat /home/ubuntu/ghumakkad/backend/lib/src/config/database.dart

⬜ 9. On server: redeploy backend
       cd /home/ubuntu/ghumakkad && ./deployment/deploy.sh
```

---

## VERIFICATION TESTS

After all fixes, test in this order:

### Test 1 — API is reachable:
```bash
curl https://ghumakkad.yuktaa.com/api/v1/auth/send-otp \
  -X POST -H "Content-Type: application/json" \
  -d '{"phone":"9999999999"}'
# Expected: {"success":true,"data":{"mock_otp":"123456"},"message":"Done"}
# If 404: Nginx fix not applied
# If connection refused: PM2/Dart server not running
```

### Test 2 — Flutter compiles:
```bash
cd frontend
flutter pub get
flutter analyze
# Should show 0 errors (maybe some warnings)
```

### Test 3 — Firebase OTP on real device:
```
1. Build debug APK: flutter build apk --debug
2. Install on Android phone
3. Enter test phone: 9999999999
4. Tap "Start Journey"
5. If button spins then shows error — run: flutter run and check console logs
6. Look for [AuthService] log lines showing real error
```

### Test 4 — Full login flow:
```
1. Enter 9999999999
2. OTP screen opens → enter 123456 (test number)
3. Profile setup screen appears (new user) or Home screen (returning user)
4. Home screen loads trips from API
```

---

## COMPLETE FIX LIST — 13 ITEMS

```
MANUAL (you must do these):
⬜ M1. Run flutterfire configure → generate firebase_options.dart
⬜ M2. Get SHA-1 (gradlew signingReport) → add to Firebase Console
⬜ M3. Re-download google-services.json after adding SHA-1
⬜ M4. Enable Phone Auth in Firebase Console
⬜ M5. Add test phone +91 9999999999 → 123456 in Firebase Console
⬜ M6. Fix Nginx on server: proxy_pass http://localhost:8080/api/;
⬜ M7. Verify/create database.dart on server with real credentials

CODE FIXES (AI agent does these):
⬜ C1.  Fix auth_provider.dart — move imports before function definition
⬜ C2.  Fix auth_service.dart — add error logging in verifyOtp + sendOtp
⬜ C3.  Fix AndroidManifest.xml — android:label="Ghumakkad"
⬜ C4.  Fix build.gradle.kts — minSdk = 21
⬜ C5.  Fix pubspec.yaml — share_plus: ^12.0.2
⬜ C6.  Fix ghumakkad.conf — proxy_pass http://localhost:8080/api/;
⬜ C7.  Fix expense_routes._create — add expense_splits INSERT logic
⬜ C8.  Fix trip_routes._list — wrap in {'trips': trips}
⬜ C9.  Fix pin_routes._create — add added_by to INSERT
⬜ C10. Complete memory_routes.dart (4 handlers)
⬜ C11. Complete ticket_routes.dart (4 handlers)
⬜ C12. Complete hotel_routes.dart (4 handlers)
⬜ C13. Complete member_routes.dart (2 handlers)
⬜ C14. Complete hisaab_routes.dart (GET + POST/settle)
⬜ C15. Complete upload_routes.dart (multipart image)
⬜ C16. Wire photo upload in add_pin_screen.dart
⬜ C17. Add UPI deep link in settlement_screen.dart
⬜ C18. Add QR + share in members_screen.dart
```

---

## CODE RULES — UNCHANGED

1. All imports at top of Dart file, before any code or declarations
2. Every route handler has try/catch, UnauthorizedException caught separately → 401
3. SQL uses ? placeholders only — never string interpolation
4. Multi-step DB operations use DB.transaction()
5. Flutter: ref.watch() for UI, ref.read(notifier) for mutations
6. CachedNetworkImage for all network images
7. Every loading screen shows loading + error state
8. Never commit database.dart, firebase_options.dart, or google-services.json

---

*Ghumakkad Antigravity Prompt v5.0*
*Firebase project: ghumakkad-e2263 | Package: in.ghumakkad.app*
*Server: 92.4.84.229 | API: https://ghumakkad.yuktaa.com/api/v1*
