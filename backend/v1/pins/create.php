<?php
// backend/v1/pins/create.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();
$data = json_decode(file_get_contents("php://input"), true);

$trip_id = $data['trip_id'] ?? 0;
$pin_type = $data['pin_type'] ?? 'memory';
$title = $data['title'] ?? '';
$latitude = $data['latitude'] ?? 0;
$longitude = $data['longitude'] ?? 0;
$address = $data['address'] ?? '';
$pinned_at = $data['pinned_at'] ?? date('Y-m-d H:i:s');

if (!$trip_id || !$latitude || !$longitude) {
    Response::json(false, null, "Trip ID, Latitude, and Longitude are required", 400);
}

$db = DB::getInstance();

// Check if user is member of trip
$stmt = $db->prepare("SELECT role FROM trip_members WHERE trip_id = ? AND user_id = ?");
$stmt->execute([$trip_id, $user['id']]);
if (!$stmt->fetch()) {
    Response::json(false, null, "You are not a member of this trip", 403);
}

try {
    $stmt = $db->prepare("INSERT INTO trip_pins (trip_id, added_by, pin_type, title, latitude, longitude, address, pinned_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$trip_id, $user['id'], $pin_type, $title, $latitude, $longitude, $address, $pinned_at]);
    $pin_id = $db->lastInsertId();

    $stmt = $db->prepare("SELECT * FROM trip_pins WHERE id = ?");
    $stmt->execute([$pin_id]);
    $pin = $stmt->fetch();

    Response::json(true, ["pin" => $pin], "Pin added successfully");
} catch (Exception $e) {
    Response::json(false, null, "Failed to add pin: " . $e->getMessage(), 500);
}
