<?php
// backend/v1/pins/list.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();
$trip_id = $_GET['trip_id'] ?? 0;

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

$stmt = $db->prepare("SELECT * FROM trip_pins WHERE trip_id = ? ORDER BY pinned_at ASC, pin_order ASC");
$stmt->execute([$trip_id]);
$pins = $stmt->fetchAll();

Response::json(true, ["pins" => $pins], "Pins fetched successfully");
