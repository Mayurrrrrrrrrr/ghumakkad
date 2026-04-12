<?php
// backend/v1/route/get.php
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

$stmt = $db->prepare("SELECT latitude, longitude FROM trip_route WHERE trip_id = ? ORDER BY point_order ASC");
$stmt->execute([$trip_id]);
$route = $stmt->fetchAll(PDO::FETCH_ASSOC);

Response::json(true, ["route" => $route], "Route fetched successfully");
