<?php
// backend/core/Auth.php
require_once __DIR__ . '/DB.php';
require_once __DIR__ . '/Response.php';

class Auth {
    // Basic middleware to check token
    public static function requireLogin() {
        $headers = apache_request_headers();
        $authHeader = $headers['Authorization'] ?? '';

        if (!$authHeader || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            Response::json(false, null, "Unauthorized: No token provided", 401);
        }

        $token = $matches[1];
        
        $db = DB::getInstance();
        $stmt = $db->prepare("SELECT u.* FROM users u JOIN auth_tokens t ON u.id = t.user_id WHERE t.token = ? AND t.expires_at > NOW() AND u.is_active = 1");
        $stmt->execute([$token]);
        $user = $stmt->fetch();

        if (!$user) {
            Response::json(false, null, "Unauthorized: Invalid or expired token", 401);
        }

        return $user;
    }
}

// polyfill if apache_request_headers not available
if (!function_exists('apache_request_headers')) {
    function apache_request_headers() {
        $arh = array();
        $rx_http = '/\AHTTP_/';
        foreach ($_SERVER as $key => $val) {
            if (preg_match($rx_http, $key)) {
                $arh_key = preg_replace($rx_http, '', $key);
                $rx_matches = array();
                $rx_matches = explode('_', $arh_key);
                if (count($rx_matches) > 0 and strlen($arh_key) > 2) {
                    foreach ($rx_matches as $ak_key => $ak_val) $rx_matches[$ak_key] = ucfirst($ak_val);
                    $arh_key = implode('-', $rx_matches);
                }
                $arh[$arh_key] = $val;
            }
        }
        return $arh;
    }
}
