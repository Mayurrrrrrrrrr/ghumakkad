<?php
// backend/v1/auth/send_otp.php
require_once __DIR__ . '/../../core/Response.php';

$data = json_decode(file_get_contents("php://input"), true);
$phone = $data['phone'] ?? '';

if (!$phone || strlen($phone) < 10) {
    Response::json(false, null, "Valid phone number is required", 400);
}

// MOCK: In production, call Firebase Auth Admin SDK or similar here.
// For now, we simulate success. The frontend will expect success so it can move to the OTP screen.
Response::json(true, ["phone" => $phone, "mock_otp" => "123456"], "OTP sent successfully");
