<?php
// backend/v1/auth/update_profile.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();

$data = json_decode(file_get_contents("php://input"), true);
$name = $data['name'] ?? $user['name'];

$db = DB::getInstance();
$stmt = $db->prepare("UPDATE users SET name = ? WHERE id = ?");
$stmt->execute([$name, $user['id']]);

$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$user['id']]);
$updatedUser = $stmt->fetch();

Response::json(true, ["user" => $updatedUser], "Profile updated");
