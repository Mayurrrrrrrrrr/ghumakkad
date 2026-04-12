<?php
// backend/v1/auth/logout.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();

$headers = apache_request_headers();
$authHeader = $headers['Authorization'] ?? '';
preg_match('/Bearer\s(\S+)/', $authHeader, $matches);
$token = $matches[1] ?? '';

if ($token) {
    $db = DB::getInstance();
    $stmt = $db->prepare("DELETE FROM auth_tokens WHERE token = ?");
    $stmt->execute([$token]);
}

Response::json(true, null, "Logged out successfully");
