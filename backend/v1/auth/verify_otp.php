<?php
// backend/v1/auth/verify_otp.php
require_once __DIR__ . '/../../core/DB.php';
require_once __DIR__ . '/../../core/Response.php';

$data = json_decode(file_get_contents("php://input"), true);
$phone = $data['phone'] ?? '';
$otp = $data['otp'] ?? '';

if (!$phone || !$otp) {
    Response::json(false, null, "Phone and OTP are required", 400);
}

// MOCK: Validate fixed OTP
if ($otp !== '123456') {
    Response::json(false, null, "Invalid OTP", 400);
}

$db = DB::getInstance();

// Check if user exists
$stmt = $db->prepare("SELECT * FROM users WHERE phone = ?");
$stmt->execute([$phone]);
$user = $stmt->fetch();

$is_new = false;
if (!$user) {
    // Create new user (name can be set in profile step later)
    $stmt = $db->prepare("INSERT INTO users (phone, name) VALUES (?, ?)");
    $stmt->execute([$phone, "Wanderer"]);
    $user_id = $db->lastInsertId();
    $is_new = true;
    
    $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();
} else {
    $user_id = $user['id'];
}

// Generate Auth Token
$token = bin2hex(random_bytes(32));
$expires_at = date('Y-m-d H:i:s', strtotime('+30 days'));

$stmt = $db->prepare("INSERT INTO auth_tokens (user_id, token, expires_at) VALUES (?, ?, ?)");
$stmt->execute([$user_id, $token, $expires_at]);

Response::json(true, [
    "user" => $user,
    "token" => $token,
    "is_new_user" => $is_new
], "Verified successfully");
