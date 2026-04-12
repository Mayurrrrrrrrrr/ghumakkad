<?php
// backend/v1/trips/list.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();
$db = DB::getInstance();

$stmt = $db->prepare("
    SELECT t.*, tm.role 
    FROM trips t 
    JOIN trip_members tm ON t.id = tm.trip_id 
    WHERE tm.user_id = ?
    ORDER BY CASE WHEN t.status = 'active' THEN 0 ELSE 1 END, t.start_date DESC
");
$stmt->execute([$user['id']]);
$trips = $stmt->fetchAll();

// Get memory counts, expense counts per trip etc. if needed later
Response::json(true, ["trips" => $trips], "Trips fetched");
