<?php

function handleFileUpload() {
    $filename = "./data.txt";
    $password = trim(file_get_contents("./password.txt"));

    if ($password == '') {
        http_response_code(500);
        header("Info: Server not configured.");
        exit;
    }

    if (!isset($_POST['password'])) {
        header("Info: password not set.");
        http_response_code(403);
        exit;
    }

    if ($_POST['password'] !== $password) {
        http_response_code(403);
        error_log("Password given: '". $_POST['password'] ."'.");
        header("Info: password is incorrect.");
        exit;
    }

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
        http_response_code(200);
        header('Content-Type: text/plain');
        header('Content-Disposition: inline; filename="' . basename($filename) . '"');
        readfile($filename);
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
