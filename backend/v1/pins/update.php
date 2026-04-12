<?php
// backend/v1/pins/update.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();
$data = json_decode(file_get_contents("php://input"), true);

$pin_id = $data['id'] ?? 0;
if (!$pin_id) {
    Response::json(false, null, "Pin ID is required", 400);
}

$db = DB::getInstance();

// Check if pin exists and user has permission (from same trip)
$stmt = $db->prepare("SELECT p.*, tm.user_id FROM trip_pins p JOIN trip_members tm ON p.trip_id = tm.trip_id WHERE p.id = ? AND tm.user_id = ?");
$stmt->execute([$pin_id, $user['id']]);
$pinData = $stmt->fetch();

if (!$pinData) {
    Response::json(false, null, "Pin not found or permission denied", 404);
}

$pin_type = $data['pin_type'] ?? $pinData['pin_type'];
$title = $data['title'] ?? $pinData['title'];
$latitude = $data['latitude'] ?? $pinData['latitude'];
$longitude = $data['longitude'] ?? $pinData['longitude'];
$address = $data['address'] ?? $pinData['address'];
$pinned_at = $data['pinned_at'] ?? $pinData['pinned_at'];

try {
    $stmt = $db->prepare("UPDATE trip_pins SET pin_type = ?, title = ?, latitude = ?, longitude = ?, address = ?, pinned_at = ? WHERE id = ?");
    $stmt->execute([$pin_type, $title, $latitude, $longitude, $address, $pinned_at, $pin_id]);

    $stmt = $db->prepare("SELECT * FROM trip_pins WHERE id = ?");
    $stmt->execute([$pin_id]);
    $updatedPin = $stmt->fetch();

    Response::json(true, ["pin" => $updatedPin], "Pin updated successfully");
} catch (Exception $e) {
    Response::json(false, null, "Failed to update pin: " . $e->getMessage(), 500);
}
