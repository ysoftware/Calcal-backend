<?php
$filename = "data.txt";

function handleFileUpload() {
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
    if (file_exists($filename) && is_readable($filename)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . basename($filename) . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($filename));
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
