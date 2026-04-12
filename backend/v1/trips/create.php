<?php
// backend/v1/trips/create.php
require_once __DIR__ . '/../../core/Auth.php';

$user = Auth::requireLogin();
$data = json_decode(file_get_contents("php://input"), true);

$title = $data['title'] ?? '';
$start_date = $data['start_date'] ?? null;
$end_date = $data['end_date'] ?? null;
$description = $data['description'] ?? null;

if (!$title) {
    Response::json(false, null, "Trip title is required", 400);
}

function generateInviteCode($length = 12) {
    return substr(str_shuffle(str_repeat($x='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', ceil($length/strlen($x)) )),1,$length);
}

function generateUUID() {
    return sprintf( '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand( 0, 0xffff ), mt_rand( 0, 0xffff ),
        mt_rand( 0, 0xffff ),
        mt_rand( 0, 0x0fff ) | 0x4000,
        mt_rand( 0, 0x3fff ) | 0x8000,
        mt_rand( 0, 0xffff ), mt_rand( 0, 0xffff ), mt_rand( 0, 0xffff )
    );
}

$uuid = generateUUID();
$invite_code = generateInviteCode();

$db = DB::getInstance();
$db->beginTransaction();

try {
    $stmt = $db->prepare("INSERT INTO trips (uuid, title, description, start_date, end_date, creator_id, invite_code) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$uuid, $title, $description, $start_date, $end_date, $user['id'], $invite_code]);
    $trip_id = $db->lastInsertId();

    $stmt = $db->prepare("INSERT INTO trip_members (trip_id, user_id, role) VALUES (?, ?, 'creator')");
    $stmt->execute([$trip_id, $user['id']]);

    $db->commit();

    $stmt = $db->prepare("SELECT * FROM trips WHERE id = ?");
    $stmt->execute([$trip_id]);
    $trip = $stmt->fetch();

    Response::json(true, ["trip" => $trip], "Trip created successfully");
} catch (Exception $e) {
    $db->rollBack();
    Response::json(false, null, "Failed to create trip: " . $e->getMessage(), 500);
}
