<?php

function handleFileUpload() {
    $filename = "./data.txt";
    if (isset($_FILES['file'])) {
        $file = $_FILES['file'];
        
        if ($file['error'] === UPLOAD_ERR_OK) {
            move_uploaded_file($file['tmp_name'], $filename);
            http_response_code(200);
        } else {
            http_response_code(500);
        }
    } else {
        http_response_code(400);
    }
}

function handleFileDownload() {
    $filename = "./data.txt";
    if (file_exists($filename) && is_readable($filename)) {
        header('Content-Type: text/plain');
        header('Content-Disposition: inline; filename="' . basename($filename) . '"');
        readfile($filename);
        http_response_code(200);
    } else {
        http_response_code(404);
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    handleFileUpload();
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    handleFileDownload();
} else {
    http_response_code(404);
}

?>
