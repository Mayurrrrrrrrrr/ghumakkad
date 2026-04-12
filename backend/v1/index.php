<?php
// backend/v1/index.php
// Main router
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Authorization, Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once __DIR__ . '/../core/Response.php';

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// Extract path relative to v1/
$scriptBase = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])); // e.g. /v1
$path = str_replace($scriptBase, '', $uri);
$path = trim($path, '/');
$pathParts = explode('/', $path);

$method = $_SERVER['REQUEST_METHOD'];

// Add basic routing
$resource = $pathParts[0] ?? '';
$action = $pathParts[1] ?? '';

switch ($resource) {
    case 'auth':
        if ($action === 'send-otp' && $method === 'POST') require __DIR__ . '/auth/send_otp.php';
        elseif ($action === 'verify-otp' && $method === 'POST') require __DIR__ . '/auth/verify_otp.php';
        elseif ($action === 'logout' && $method === 'POST') require __DIR__ . '/auth/logout.php';
        elseif ($action === 'update-profile' && $method === 'PUT') require __DIR__ . '/auth/update_profile.php';
        else Response::json(false, null, "Endpoint not found", 404);
        break;
    
    case 'trips':
        if ($method === 'GET' && empty($action)) require __DIR__ . '/trips/list.php';
        elseif ($method === 'POST' && empty($action)) require __DIR__ . '/trips/create.php';
        elseif ($method === 'GET' && !empty($action) && empty($pathParts[2])) {
            $_GET['trip_id'] = $action;
            require __DIR__ . '/trips/detail.php';
        }
        else Response::json(false, null, "Endpoint not found or not implemented", 404);
        break;

    case 'pins':
        // URI format: /pins/{pin_id} or /trips/{trip_id}/pins
        // Simplified router logic for pins:
        if ($method === 'GET') require __DIR__ . '/pins/list.php';
        elseif ($method === 'POST') require __DIR__ . '/pins/create.php';
        elseif ($method === 'PUT') require __DIR__ . '/pins/update.php';
        elseif ($method === 'DELETE') require __DIR__ . '/pins/delete.php';
        break;

    case 'route':
        if ($method === 'GET') require __DIR__ . '/route/get.php';
        elseif ($method === 'POST') require __DIR__ . '/route/save.php';
        break;
        
    default:
        Response::json(false, null, "API Endpoint not found", 404);
}
