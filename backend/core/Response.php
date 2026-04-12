<?php
// backend/core/Response.php

class Response {
    public static function json($success, $data = [], $message = "Done", $status_code = 200) {
        http_response_code($status_code);
        header('Content-Type: application/json; charset=utf-8');
        
        $response = [
            "success" => $success,
            "data" => $data,
            "message" => $message
        ];
        
        echo json_encode($response);
        exit();
    }
}
