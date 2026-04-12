<?php
// backend/v1/pins/delete.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();
$data = json_decode(file_get_contents("php://input"), true);

$pin_id = $data['id'] ?? 0;
if (!$pin_id) {
    Response::json(false, null, "Pin ID is required", 400);
}

$db = DB::getInstance();

// Check permission
$stmt = $db->prepare("SELECT p.trip_id FROM trip_pins p JOIN trip_members tm ON p.trip_id = tm.trip_id WHERE p.id = ? AND tm.user_id = ?");
$stmt->execute([$pin_id, $user['id']]);
if (!$stmt->fetch()) {
    Response::json(false, null, "Pin not found or permission denied", 404);
}

try {
    $stmt = $db->prepare("DELETE FROM trip_pins WHERE id = ?");
    $stmt->execute([$pin_id]);
    Response::json(true, null, "Pin deleted successfully");
} catch (Exception $e) {
    Response::json(false, null, "Failed to delete pin: " . $e->getMessage(), 500);
}
