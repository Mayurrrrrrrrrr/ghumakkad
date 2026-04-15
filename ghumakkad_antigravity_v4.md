# GHUMAKKAD — Antigravity Prompt v4.0
### Full code review + Firebase login diagnosis + complete continuation prompt

---

# PART 1 — CURRENT STATUS REPORT

## What's Built (Impressive progress)

### Backend — 90% complete ✅
- `bin/server.dart` — full server with CORS, all routes mounted ✅
- `core/db.dart` — MySQL singleton with transaction helper ✅
- `core/auth.dart` — Bearer token middleware ✅
- `core/response.dart` — JSON helpers ✅
- `routes/auth_routes.dart` — Firebase token exchange, user creation, logout ✅
- `routes/trip_routes.dart` — full CRUD, join, transfer, invite link ✅
- `routes/pin_routes.dart` — full CRUD + reorder ✅
- `routes/expense_routes.dart` — list + create with split logic ✅
- `routes/hisaab_routes.dart` — exists ✅
- `services/hisaab_service.dart` — settlement algorithm (correct) ✅
- `routes/memory_routes.dart` — exists ✅
- `routes/ticket_routes.dart` — exists ✅
- `routes/hotel_routes.dart` — exists ✅
- `routes/member_routes.dart` — exists ✅
- `routes/upload_routes.dart` — exists ✅
- `pm2.config.js` — correct, points to compiled binary ✅
- `ghumakkad.conf` (Nginx) — correct, SSL + proxy ✅
- `deployment/deploy.sh` — correct compile + restart ✅

### Frontend — 85% complete ✅
- All models: trip, trip_pin, expense, split, memory, ticket, hotel, settlement ✅
- All providers wired to real API ✅
- All screens exist: home, map, hisaab, timeline, docs, members, profile, anniversary ✅
- Home screen wired to tripsProvider (real API, not dummy data) ✅
- Auth flow: Firebase OTP → token exchange → SharedPrefs ✅
- Trip dashboard wired to all 4 screens ✅

---

## THE FIREBASE LOGIN PROBLEM — Root Cause Analysis

This is the #1 critical bug. Here are ALL the reasons Firebase login fails:

### Bug 1 — `google-services.json` is MISSING from the repo 🔴 CRITICAL
Firebase requires `frontend/android/app/google-services.json` to exist.
Without it, `Firebase.initializeApp()` in `main.dart` throws an exception at startup
and the entire app crashes before reaching the login screen.

The file is not in the repo (correctly gitignored) but must be present on the
build machine. This is almost certainly why login doesn't work.

**Fix:** Download `google-services.json` from Firebase Console →
Project Settings → Your Android app → Download config file →
Place at `frontend/android/app/google-services.json`
(Never commit this file — keep it gitignored)

### Bug 2 — SHA-1 fingerprint not registered in Firebase 🔴 CRITICAL
Firebase Phone Auth requires the debug SHA-1 of your keystore registered
in the Firebase Console under Project Settings → Android app → SHA certificate fingerprints.

Without this, `verifyPhoneNumber()` silently fails — no error, no OTP sent.

**Fix:** Run on your dev machine:
```bash
cd frontend/android
./gradlew signingReport
```
Copy the SHA-1 from "debug" variant → paste into Firebase Console → Save.

### Bug 3 — `main.dart` calls `Firebase.initializeApp()` with no options 🔴
```dart
// Current (broken):
await Firebase.initializeApp();

// Fix — must pass options from google-services.json:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```
This requires running `flutterfire configure` to generate
`lib/firebase_options.dart`. Without this, initializeApp fails on newer
Firebase SDK versions (firebase_core ^4.x).

**Fix:**
```bash
# Install flutterfire CLI if not done:
dart pub global activate flutterfire_cli

# In frontend/ folder:
flutterfire configure
# Select your Firebase project → Android → confirm
# This generates: frontend/lib/firebase_options.dart
```

Then update `main.dart`:
```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: GhumakkadApp()));
}
```

### Bug 4 — Phone Auth not enabled in Firebase Console 🟡 LIKELY
Even with correct setup, if Phone Authentication is not enabled:
Firebase Console → Authentication → Sign-in method → Phone → Enable

### Bug 5 — Test phone numbers not whitelisted (for development) 🟡
Firebase blocks real SMS to unverified numbers during development unless
you whitelist test numbers.
Firebase Console → Authentication → Sign-in method → Phone →
Add test phone number (e.g. +91 9999999999 → code: 123456)

### Bug 6 — `tripsProvider` response parsing crash 🟠 LIKELY
After login succeeds, home screen calls `GET /trips` and tries:
```dart
final List list = response.data['data']['trips'];
```
But `trip_routes.dart` returns the list directly (not under a 'trips' key):
```dart
return ApiResponse.ok(trips);  // data = [] not data = {'trips': []}
```
This causes a null cast exception that looks like a login failure.

**Fix in `trips_provider.dart`:**
```dart
// Change this:
final List list = response.data['data']['trips'];
// To this:
final rawData = response.data['data'];
final List list = rawData is List ? rawData : (rawData['trips'] ?? []);
```

### Bug 7 — Nginx proxy strips `/api/` prefix 🟠
In `ghumakkad.conf`:
```nginx
location /api/ {
    proxy_pass http://localhost:8080/;  # ← trailing slash strips /api/
}
```
This means a request to `https://ghumakkad.yuktaa.com/api/v1/auth/verify-otp`
arrives at the Dart server as `/v1/auth/verify-otp` — correct.
But `ApiConstants.baseUrl = 'https://ghumakkad.yuktaa.com/api/v1'` combined with
Dio endpoint `/auth/verify-otp` produces:
`https://ghumakkad.yuktaa.com/api/v1/auth/verify-otp`
→ after Nginx strip: `/v1/auth/verify-otp`
→ Dart router mounted at `/api/v1/auth/` looks for `/api/v1/auth/verify-otp`

**The path never matches.** The Dart router gets `/v1/auth/verify-otp` but
expects `/api/v1/auth/verify-otp`.

**Fix — TWO OPTIONS (pick one):**

Option A (fix Nginx — recommended):
```nginx
location /api/ {
    proxy_pass http://localhost:8080/api/;  # keep /api/ prefix
}
```

Option B (fix Dart server routes):
```dart
// Change all mounts in server.dart from:
router.mount('/api/v1/auth/', AuthRoutes().router);
// To:
router.mount('/v1/auth/', AuthRoutes().router);
```

### Bug 8 — `database.dart` committed with real password 🔴 SECURITY
`backend/lib/src/config/database.dart` is committed to the public repo
with real credentials: `password: 'Mayur@12345'`

**Fix immediately:**
1. Change the MySQL password on the server
2. Add `backend/lib/src/config/database.dart` to `backend/.gitignore`
3. Commit only `database.dart.example`

---

## Other Issues Found

### Flutter compile warnings (from analyze.txt)
- `withOpacity` deprecated — use `withValues(alpha:)` instead
- Some screens import paths use `../../../` (3 levels) but should be `../../` — check for broken imports
- `hisaab_screen.dart` and `timeline_screen.dart` import paths use wrong depth (`../../../models/` instead of `../../models/`)

### `profile_setup_screen.dart` — broken completion flow
After user enters name and taps "Start Wandering", it only calls `checkAuth()`
but never calls `PUT /auth/update-profile` to save the name.
The user ends up stuck as "Wanderer" forever.

### `trips_provider.dart` — wrong response key
```dart
final List list = response.data['data']['trips'];
// Backend returns: {"success": true, "data": [...]}  ← data is the array directly
// Not: {"success": true, "data": {"trips": [...]}}
```

### `pin_routes.dart` — `added_by` missing in INSERT
```dart
INSERT INTO trip_pins (trip_id, pin_type, title, latitude, longitude, address, pinned_at)
// Missing: added_by = user['id']
```

### `trip_routes.dart` — `_list` response format
Returns array directly but `tripsProvider` expects it under key `trips`:
```dart
return ApiResponse.ok(trips);           // returns [] 
// tripsProvider reads: response.data['data']['trips']  ← crashes
```

---

# PART 2 — COMPLETE ANTIGRAVITY PROMPT v4.0

---

## WHO YOU ARE & WHAT YOU ARE DOING

Continuing development of **Ghumakkad** (घुमक्कड़) — a Flutter mobile app for friends
to record trip memories, manage travel docs, and split expenses.

**Repo:** `https://github.com/Mayurrrrrrrrrr/ghumakkad`
**Server:** `92.4.84.229` | Nginx → PM2 → Dart binary on port 8080
**API base:** `https://ghumakkad.yuktaa.com/api/v1`
**App package:** `in.ghumakkad.app`

Stack: Flutter + Riverpod + Dio | Dart shelf backend | MySQL 8 | Firebase Phone Auth

---

## DO NOT REWRITE — THESE ARE CORRECT ✅

Everything listed in Part 1 "What's Built" section above.
Backend is 90% done. Frontend is 85% done.
Only fix bugs and build the missing pieces listed below.

---

## PRIORITY 1 — FIREBASE LOGIN FIXES (do these first)

### Fix 1A: `frontend/lib/main.dart`

Run `flutterfire configure` in the frontend directory first to generate
`frontend/lib/firebase_options.dart`. Then update main.dart:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // ← ADD THIS
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // ← ADD OPTIONS
  );
  runApp(
    const ProviderScope(
      child: GhumakkadApp(),
    ),
  );
}
```

### Fix 1B: Nginx config `ghumakkad.conf`

The current config strips `/api/` from the path before sending to Dart.
Fix by keeping the prefix:

```nginx
location /api/ {
    proxy_pass http://localhost:8080/api/;   # ← was http://localhost:8080/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 10M;
}
```

After editing on server: `sudo nginx -t && sudo systemctl reload nginx`

### Fix 1C: Security — remove `database.dart` from git

```bash
# In repo root:
echo "backend/lib/src/config/database.dart" >> backend/.gitignore
git rm --cached backend/lib/src/config/database.dart
git commit -m "fix: remove credentials from repo"
```

Then change the MySQL password on the server.

---

## PRIORITY 2 — BACKEND BUGS

### Fix 2A: `backend/lib/src/routes/trip_routes.dart` — `_list` response

```dart
// CHANGE:
return ApiResponse.ok(trips);

// TO (wrap in map so frontend key 'trips' works):
return ApiResponse.ok({'trips': trips});
```

### Fix 2B: `backend/lib/src/routes/pin_routes.dart` — missing `added_by`

```dart
// CHANGE the INSERT in _create:
final res = await DB.execute('''
  INSERT INTO trip_pins (trip_id, added_by, pin_type, title, latitude, longitude, address, pinned_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''', [
  tripId,
  user['id'],   // ← ADD THIS
  body['pin_type'] ?? 'memory',
  body['title'],
  body['latitude'],
  body['longitude'],
  body['address'],
  body['pinned_at'] ?? DateTime.now().toIso8601String(),
]);
```

### Fix 2C: Verify all remaining routes compile and respond

Check these route files exist and are complete (review each):
- `memory_routes.dart` — must handle: GET /?pin_id=X, POST /, DELETE /<id>, GET /trip/<tripId>
- `ticket_routes.dart` — GET /?trip_id=X, POST /, PUT /<id>, DELETE /<id>
- `hotel_routes.dart` — same pattern as tickets
- `member_routes.dart` — GET /?trip_id=X, DELETE /
- `hisaab_routes.dart` — GET /<tripId>, POST /<tripId>/settle
- `upload_routes.dart` — POST /image (multipart)

For each file that is incomplete (scaffold only), complete it following
the pattern established in `trip_routes.dart` and `pin_routes.dart`.

### Fix 2D: `expense_routes.dart` — complete the `_create` method

The file was cut off mid-function. The `_create` method needs the split logic
(equal/custom/individual). Implement:

```dart
// After INSERT trip_expenses:
newExpenseId = res.insertId;

if (splitType == 'equal') {
  // Get members to split among
  List<dynamic> memberIds;
  if (body['split_among'] != null) {
    memberIds = body['split_among'] as List;
  } else {
    // All trip members
    final allMembers = await DB.query(
      'SELECT user_id FROM trip_members WHERE trip_id = ?', [tripId]
    );
    memberIds = allMembers.map((m) => m['user_id']).toList();
  }
  
  final share = amount / memberIds.length;
  // Round: first member gets remainder
  final roundedShare = double.parse(share.toStringAsFixed(2));
  final remainder = double.parse(
    (amount - roundedShare * memberIds.length).toStringAsFixed(2)
  );
  
  for (int i = 0; i < memberIds.length; i++) {
    final memberShare = i == 0 ? roundedShare + remainder : roundedShare;
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

## PRIORITY 3 — FLUTTER BUGS

### Fix 3A: `frontend/lib/providers/trips_provider.dart`

```dart
final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get(ApiConstants.trips);
  
  if (response.data['success'] == true) {
    // Backend wraps in {'trips': [...]} after Fix 2A
    final rawData = response.data['data'];
    final List list = rawData is List ? rawData : (rawData['trips'] ?? []);
    return list.map((e) => Trip.fromJson(e)).toList();
  }
  return [];
});
```

### Fix 3B: `frontend/lib/screens/onboarding/profile_setup_screen.dart`

The `_completeSetup` method never saves the name to backend. Fix:

```dart
void _completeSetup() async {
  final name = _nameController.text.trim();
  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter your name")),
    );
    return;
  }

  setState(() => _isLoading = true);
  
  try {
    // Save name to backend
    final apiService = ref.read(apiServiceProvider);
    await apiService.put(ApiConstants.updateProfile, data: {'name': name});
    
    // Update local storage
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      final userData = json.decode(userDataStr) as Map<String, dynamic>;
      userData['name'] = name;
      await prefs.setString('user_data', json.encode(userData));
    }
  } catch (e) {
    // Continue even if update fails
  }
  
  // Transition to main app
  await ref.read(authProvider.notifier).checkAuth();
  setState(() => _isLoading = false);
}
```

Also add these imports to `profile_setup_screen.dart`:
```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
```

### Fix 3C: Fix broken import paths in screens

Several screens under `frontend/lib/screens/trip/` use `../../../` (3 levels up)
but should use `../../` (2 levels up) for models and providers.

Check and fix imports in:
- `hisaab_screen.dart` — change `../../../models/` → `../../models/`
- `timeline_screen.dart` — change `../../../models/` → `../../models/`
- `add_expense_screen.dart` — verify all import paths
- `settlement_screen.dart` — verify all import paths

Correct import pattern from `frontend/lib/screens/trip/`:
```dart
import '../../models/trip.dart';         // ✅ correct
import '../../providers/hisaab_provider.dart';  // ✅ correct
import '../../core/constants/app_colors.dart';  // ✅ correct
```

### Fix 3D: `timeline_screen.dart` — 'Mine' filter

The 'Mine' filter has a placeholder comment. Wire it properly:

```dart
// Add a provider for current user ID:
// In auth_provider.dart, add:
Future<int?> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userDataStr = prefs.getString('user_data');
  if (userDataStr == null) return null;
  final userData = json.decode(userDataStr);
  return userData['id'] as int?;
}

// In timeline_screen.dart, add to state:
int? _currentUserId;

@override
void initState() {
  super.initState();
  _loadCurrentUser();
}

Future<void> _loadCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userDataStr = prefs.getString('user_data');
  if (userDataStr != null) {
    final userData = json.decode(userDataStr);
    setState(() => _currentUserId = userData['id']);
  }
}

// Then in filter logic:
} else if (_filter == 'Mine' && _currentUserId != null) {
  filtered = memories.where((m) => m.addedBy == _currentUserId).toList();
}
```

---

## PRIORITY 4 — MISSING BACKEND ROUTE FILES

If any of these route files are incomplete scaffolds, complete them now.
Each follows the same pattern as `trip_routes.dart`. Here is the spec:

### `memory_routes.dart` — complete spec

```
Router mounts at: /api/v1/memories/

GET  /?pin_id=X
  - Auth required, must be member of parent trip
  - JOIN pin_memories → users for added_by info
  - Return list of memories

POST /
  - Auth required, must be member
  - Body: { pin_id, memory_type (photo/note), content, caption? }
  - INSERT pin_memories (pin_id, added_by=user.id, memory_type, content, caption)

DELETE /<memoryId>
  - Auth required
  - Only the person who added it can delete (added_by = user.id)
  - DELETE FROM pin_memories WHERE id=? AND added_by=?

GET /trip/<tripId>
  - Auth required, must be member
  - Returns ALL memories across entire trip (for timeline)
  - Query:
    SELECT pm.*, tp.title as pin_title, tp.latitude, tp.longitude,
           tp.address, tp.pinned_at,
           u.name as added_by_name, u.avatar_url as added_by_avatar
    FROM pin_memories pm
    JOIN trip_pins tp ON pm.pin_id = tp.id
    JOIN users u ON pm.added_by = u.id
    WHERE tp.trip_id = ?
    ORDER BY tp.pinned_at ASC, pm.created_at ASC
```

### `ticket_routes.dart` — complete spec

```
Router mounts at: /api/v1/tickets/

GET  /?trip_id=X  — list tickets for trip
POST /            — add ticket
  Body: { trip_id, ticket_type, from_place, to_place, travel_date?,
          travel_time?, pnr_number?, amount?, pin_id?, ticket_image_url?, notes? }
  added_by = user.id

PUT  /<ticketId>  — update (added_by OR creator)
DELETE /<ticketId>— delete (added_by OR creator)
```

### `hotel_routes.dart` — complete spec

```
Router mounts at: /api/v1/hotels/

Same pattern as tickets.
Body fields: { trip_id, hotel_name, city?, check_in?, check_out?,
               confirmation_no?, amount?, pin_id?, booking_image_url?, notes? }
```

### `member_routes.dart` — complete spec

```
Router mounts at: /api/v1/members/

GET /?trip_id=X
  - Auth required, must be member
  - SELECT u.id, u.name, u.avatar_url, u.phone, tm.role
    FROM trip_members tm JOIN users u ON tm.user_id = u.id
    WHERE tm.trip_id = ?

DELETE /
  - Auth required, CREATOR ONLY
  - Body: { trip_id, user_id }
  - Cannot remove yourself
  - Check: requesting user is creator of the trip
  - DELETE FROM trip_members WHERE trip_id=? AND user_id=?
```

### `hisaab_routes.dart` — complete spec

```
Router mounts at: /api/v1/hisaab/

GET /<tripId>
  - Auth required, member
  - Calls HisaabService.calculateSettlement(tripId)
  - Returns { settlements, per_member_summary, trip_total }

POST /<tripId>/settle
  - Auth required, member
  - Body: { expense_split_id }
  - UPDATE expense_splits SET is_settled=1, settled_at=NOW() WHERE id=?
  - Verify the split belongs to this trip first
```

### `upload_routes.dart` — complete spec

```dart
// POST /api/v1/upload/image
// Multipart form-data, field: 'image'
// Validate: jpg/png/webp, max 5MB
// Save to: /var/www/ghumakkad/uploads/{year}/{month}/{randomHex}.{ext}
// Return: { url: 'https://ghumakkad.yuktaa.com/uploads/...' }

// Use shelf's request.read() to get bytes
// Parse multipart using 'mime' package's MimeMultipartTransformer
// Write bytes to file using dart:io File

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

Future<Response> _uploadImage(Request request) async {
  try {
    final user = await Auth.requireLogin(request);

    final contentType = request.headers['content-type'] ?? '';
    if (!contentType.contains('multipart/form-data')) {
      return ApiResponse.error('multipart/form-data required');
    }

    final boundary = contentType.split('boundary=').last.trim();
    final bytes = await request.read().expand((x) => x).toList();
    final stream = Stream.fromIterable([Uint8List.fromList(bytes)]);
    final parts = stream.transform(MimeMultipartTransformer(boundary));

    Uint8List? fileBytes;
    String? mimeType;
    String? originalFilename;

    await for (final part in parts) {
      final disposition = part.headers['content-disposition'] ?? '';
      if (disposition.contains('name="image"')) {
        mimeType = part.headers['content-type'] ?? 'image/jpeg';
        final partBytes = await part.expand((x) => x).toList();
        fileBytes = Uint8List.fromList(partBytes);
        final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
        originalFilename = match?.group(1);
      }
    }

    if (fileBytes == null) return ApiResponse.error('No image provided');

    final allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!allowedTypes.contains(mimeType)) {
      return ApiResponse.error('Only JPG, PNG, WebP allowed');
    }

    if (fileBytes.length > 5 * 1024 * 1024) {
      return ApiResponse.error('Max file size is 5MB');
    }

    final ext = mimeType == 'image/png' ? 'png' 
               : mimeType == 'image/webp' ? 'webp' 
               : 'jpg';

    final now = DateTime.now();
    final yearMonth = '${now.year}/${now.month.toString().padLeft(2, '0')}';
    final dir = Directory('/var/www/ghumakkad/uploads/$yearMonth');
    await dir.create(recursive: true);

    final random = Random.secure();
    final nameBytes = List<int>.generate(8, (_) => random.nextInt(256));
    final filename = '${nameBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}.$ext';

    await File('${dir.path}/$filename').writeAsBytes(fileBytes);

    final url = 'https://ghumakkad.yuktaa.com/uploads/$yearMonth/$filename';
    return ApiResponse.ok({'url': url});

  } on UnauthorizedException {
    return ApiResponse.unauthorized();
  } catch (e) {
    return ApiResponse.serverError(e.toString());
  }
}
```

---

## PRIORITY 5 — FLUTTER: REMAINING INCOMPLETE SCREENS

These screens exist but need completion. Check each one and finish any
placeholder/TODO sections:

### `add_expense_screen.dart` — verify split UI is complete
- Equal split: show all member names + auto-calculated share per person
- Custom split: editable amount per member + validation (sum must equal total)
- Individual: dropdown of members
- `paid_by` dropdown must show actual trip members (fetch from membersProvider)

Members provider to use:
```dart
final membersProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, tripId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get(
    ApiConstants.members, 
    queryParameters: {'trip_id': tripId.toString()}
  );
  if (response.data['success'] == true) {
    final data = response.data['data'];
    return List<Map<String, dynamic>>.from(data is List ? data : data['members'] ?? []);
  }
  return [];
});
```

### `add_pin_screen.dart` — wire actual photo upload

Replace the placeholder photo box with real image_picker + upload:

```dart
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Add to state:
XFile? _selectedImage;
String? _uploadedImageUrl;
bool _isUploading = false;

// Photo picker widget:
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
    child: _selectedImage != null
      ? ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
        )
      : _isUploading
        ? const Center(child: CircularProgressIndicator())
        : const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
  ),
)

// Method:
Future<void> _pickAndUploadImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  if (image == null) return;
  
  setState(() { _selectedImage = image; _isUploading = true; });
  
  try {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.client.post('/upload/image', data: formData);
    if (response.data['success'] == true) {
      _uploadedImageUrl = response.data['data']['url'];
    }
  } catch (e) {
    // handle error
  } finally {
    setState(() => _isUploading = false);
  }
}

// After saving pin, also save memory if image was uploaded:
Future<void> _savePin() async {
  // ... existing pin save ...
  
  if (success && _uploadedImageUrl != null) {
    // Save as memory on this pin
    final newPin = // get pin_id from addPin response
    await apiService.post('/memories', data: {
      'pin_id': newPinId,
      'memory_type': 'photo',
      'content': _uploadedImageUrl,
      'caption': _titleController.text,
    });
  }
}
```

### `members_screen.dart` — wire invite QR code

Add `qr_flutter` widget to show invite code:
```dart
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

// In invite section:
QrImageView(
  data: 'https://ghumakkad.yuktaa.com/join/${trip.inviteCode}',
  version: QrVersions.auto,
  size: 200.0,
)

// Share button:
ElevatedButton.icon(
  onPressed: () => Share.share(
    'Join my trip "${trip.title}" on Ghumakkad!\nhttps://ghumakkad.yuktaa.com/join/${trip.inviteCode}'
  ),
  icon: const Icon(Icons.share),
  label: const Text('Share Invite Link'),
)
```

### `settlement_screen.dart` — wire UPI deep link

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> _openUpi(Settlement settlement) async {
  final upiUrl = Uri.parse(
    'upi://pay?am=${settlement.amount.toStringAsFixed(2)}&cu=INR'
    '&tn=Ghumakkad%3A${Uri.encodeComponent(trip.title)}'
  );
  
  if (await canLaunchUrl(upiUrl)) {
    await launchUrl(upiUrl, mode: LaunchMode.externalApplication);
  } else {
    // Fallback: show payment amount in a dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pay via UPI'),
        content: Text('Amount: ₹${settlement.amount.toStringAsFixed(2)}\nTo: ${settlement.toUser['name']}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}
```

---

## PRIORITY 6 — ANDROID MANIFEST

Ensure `frontend/android/app/src/main/AndroidManifest.xml` has ALL of these:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

Also ensure `android/app/build.gradle.kts` has `minSdk = 21` or higher
(Firebase Phone Auth requires minSdk 19+, recommend 21).

---

## PRIORITY 7 — FINAL DEPLOY VERIFICATION

After all fixes, test on server in this order:

```bash
# 1. Test Dart server compiles
cd /home/ubuntu/ghumakkad/backend
dart pub get
dart compile exe bin/server.dart -o ghumakkad_server

# 2. Test Nginx config
sudo nginx -t

# 3. Restart everything
pm2 restart ghumakkad-api
sudo systemctl reload nginx

# 4. Test auth endpoint directly
curl -X POST https://ghumakkad.yuktaa.com/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9999999999"}'
# Expected: {"success":true,"data":{"mock_otp":"123456"},"message":"Done"}

# 5. Test verify-otp (after Firebase OTP flow):
curl -X POST https://ghumakkad.yuktaa.com/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9999999999","firebase_token":"TEST_TOKEN"}'
# Should return user + token

# 6. Test trips list (with real token):
curl https://ghumakkad.yuktaa.com/api/v1/trips/ \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
# Expected: {"success":true,"data":{"trips":[]},"message":"Done"}
```

---

## COMPLETE TODO LIST — 20 TASKS

```
SECURITY (do immediately):
⬜ 1.  Remove database.dart from git, change MySQL password

FIREBASE (do before anything else):
⬜ 2.  Run `flutterfire configure` → generate firebase_options.dart
⬜ 3.  Update main.dart to use DefaultFirebaseOptions
⬜ 4.  Enable Phone Auth in Firebase Console
⬜ 5.  Add SHA-1 fingerprint to Firebase Console (run gradlew signingReport)
⬜ 6.  Add test phone number in Firebase Console (for dev testing)

NGINX:
⬜ 7.  Fix proxy_pass to keep /api/ prefix: `proxy_pass http://localhost:8080/api/;`

BACKEND BUGS:
⬜ 8.  Fix trip_routes._list: wrap response in {'trips': trips}
⬜ 9.  Fix pin_routes._create: add `added_by` to INSERT
⬜ 10. Complete expense_routes._create split logic

BACKEND ROUTES (complete if scaffolds):
⬜ 11. Complete memory_routes.dart (all 4 endpoints)
⬜ 12. Complete ticket_routes.dart
⬜ 13. Complete hotel_routes.dart
⬜ 14. Complete member_routes.dart
⬜ 15. Complete hisaab_routes.dart + settle endpoint
⬜ 16. Complete upload_routes.dart (multipart image upload)

FLUTTER BUGS:
⬜ 17. Fix trips_provider: handle both array and {trips:[]} response formats
⬜ 18. Fix profile_setup_screen: call PUT /auth/update-profile + save to prefs
⬜ 19. Fix import paths in hisaab_screen, timeline_screen (../../../ → ../../)
⬜ 20. Fix timeline 'Mine' filter with real currentUserId

FLUTTER FEATURES:
⬜ 21. Wire photo upload in add_pin_screen + save as memory after pin creation
⬜ 22. Wire members to add_expense_screen paid_by + split_among dropdowns
⬜ 23. Add QR code + share button to members_screen invite section
⬜ 24. Add UPI deep link to settlement_screen
⬜ 25. Add Android permissions to AndroidManifest.xml

DEPLOY & TEST:
⬜ 26. Deploy, run curl tests on all 6 test commands above
⬜ 27. Build debug APK, test login on real Android device
```

---

## CODE RULES — ALWAYS FOLLOW

1. Every route handler: try/catch, UnauthorizedException caught separately → 401
2. Every SQL uses `?` placeholders — never string interpolation
3. Multi-step DB operations use `DB.transaction()`
4. All responses use `ApiResponse.ok()` / `ApiResponse.error()`
5. Flutter: `ref.watch()` for UI, `ref.read(notifier)` for mutations
6. `CachedNetworkImage` for all network images — never `Image.network` for user content
7. Every loading screen shows loading state AND error state
8. Never commit `database.dart` or `google-services.json`

---

*Ghumakkad Antigravity Prompt v4.0*
*Server: 92.4.84.229 | Dart shelf + MySQL 8 + Nginx + PM2 + Cloudflare + Firebase*
*Flutter + Riverpod + Dio + flutter_map | Package: in.ghumakkad.app*
*Based on full code review — April 2026*
