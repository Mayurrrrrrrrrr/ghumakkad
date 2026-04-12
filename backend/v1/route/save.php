<?php
// backend/v1/route/save.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();
$data = json_decode(file_get_contents("php://input"), true);

$trip_id = $data['trip_id'] ?? 0;
$points = $data['points'] ?? []; // Array of {lat: ..., lng: ...}

if (!$trip_id) {
    Response::json(false, null, "Trip ID is required", 400);
}

$db = DB::getInstance();

// Check membership
$stmt = $db->prepare("SELECT role FROM trip_members WHERE trip_id = ? AND user_id = ?");
$stmt->execute([$trip_id, $user['id']]);
if (!$stmt->fetch()) {
    Response::json(false, null, "You are not a member of this trip", 403);
}

try {
    $db->beginTransaction();

    // Clear existing route points
    $stmt = $db->prepare("DELETE FROM trip_route WHERE trip_id = ?");
    $stmt->execute([$trip_id]);

    // Insert new points
    if (!empty($points)) {
        $stmt = $db->prepare("INSERT INTO trip_route (trip_id, latitude, longitude, point_order) VALUES (?, ?, ?, ?)");
        $order = 0;
        foreach ($points as $point) {
            $stmt->execute([$trip_id, $point['latitude'], $point['longitude'], $order++]);
        }
    }

    $db->commit();
    Response::json(true, null, "Route saved successfully");
} catch (Exception $e) {
    if ($db->inTransaction()) $db->rollBack();
    Response::json(false, null, "Failed to save route: " . $e->getMessage(), 500);
}
