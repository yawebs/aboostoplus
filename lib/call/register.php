<?php
// register.php
declare(strict_types=1);

// TEMPORARY — remove before going to production, this leaks internals
error_reporting(E_ALL);
ini_set('display_errors', '1');
ini_set('display_startup_errors', '1');
error_log('--- register.php hit at ' . date('c') . ' ---'); // confirms the request even reached PHP

set_error_handler(function ($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

register_shutdown_function(function () {
    $err = error_get_last();
    if ($err !== null && in_array($err['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR], true)) {
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Fatal error',
            'error'   => $err['message'],
            'file'    => $err['file'],
            'line'    => $err['line'],
        ]);
    }
});

header('Content-Type: application/json');
require __DIR__ . '/../include/db_con.php';

const TOKEN_LIFETIME_DAYS = 30;

// Adjust these to your actual server paths/URLs
const UPLOAD_DIR = __DIR__ . '/../uploads/';
const UPLOAD_URL_BASE = 'https://aboostoplus.com/uploads/';
const MAX_UPLOAD_BYTES = 5 * 1024 * 1024; // 5MB
const ALLOWED_MIME = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp',
];

function generateUniqueId(): string
{
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    $id = '';
    for ($i = 0; $i < 10; $i++) {
        $id .= $chars[random_int(0, strlen($chars) - 1)];
    }
    return $id;
}

/**
 * Validates and moves the uploaded profileImage (if any).
 * Returns the public URL to store in the DB, or the default avatar
 * if no file was sent.
 */
function handleProfileImageUpload(): string
{
    $default = 'https://www.w3schools.com/howto/img_avatar.png';

    if (!isset($_FILES['profileImage']) || $_FILES['profileImage']['error'] === UPLOAD_ERR_NO_FILE) {
        return $default;
    }

    $file = $_FILES['profileImage'];

    if ($file['error'] !== UPLOAD_ERR_OK) {
        throw new RuntimeException('Upload failed with error code ' . $file['error']);
    }

    if ($file['size'] > MAX_UPLOAD_BYTES) {
        throw new RuntimeException('Profile image exceeds the 5MB limit');
    }

    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime  = $finfo->file($file['tmp_name']);

    if (!isset(ALLOWED_MIME[$mime])) {
        throw new RuntimeException('Profile image must be JPEG, PNG, or WEBP');
    }

    if (!is_dir(UPLOAD_DIR) && !mkdir(UPLOAD_DIR, 0755, true) && !is_dir(UPLOAD_DIR)) {
        throw new RuntimeException('Could not prepare upload directory');
    }

    $filename = generateUniqueId() . '_' . time() . '.' . ALLOWED_MIME[$mime];
    $destPath = UPLOAD_DIR . $filename;

    if (!move_uploaded_file($file['tmp_name'], $destPath)) {
        throw new RuntimeException('Could not save profile image');
    }

    return "https://aboostoplus.com/" . $filename;
}
$signupData = $_POST['signup_data'];
// Text fields now come from $_POST (multipart/form-data), not php://input
$firstName = trim($signupData['first_name'] ?? '');
$lastName  = trim($signupData['last_name'] ?? '');
$email     = trim($signupData['email'] ?? '');
$password  = $signupData['password'] ?? '';
$phone     = trim($signupData['phone'] ?? '');
$userType  = $signupData['user_type'] ?? 'User';
$notificationId = $signupData['notification_id'] ?? '';

if ($firstName === '' || $lastName === '' || $email === '' || strlen($password) < 6) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Missing required fields, or password under 6 characters']);
    exit;
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Invalid email address']);
    exit;
}

$dupe = $pdo->prepare('SELECT 1 FROM users WHERE email = ?');
$dupe->execute([$email]);
if ($dupe->fetchColumn()) {
    http_response_code(409);
    echo json_encode(['success' => false, 'message' => 'An account with this email already exists']);
    exit;
}

try {
    $profileImageUrl = handleProfileImageUpload();
} catch (RuntimeException $e) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    exit;
}

$uniqueId = generateUniqueId();
$hash     = password_hash($password, PASSWORD_BCRYPT);

try {
    $pdo->beginTransaction();

    $pdo->prepare(
        'INSERT INTO users
           (uniqueId, firstname, lastname, email, profileImage, userType, uAddress, uState, city, leadUid, phone, notification_token, user_pwd)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([
        $uniqueId,
        $firstName,
        $lastName,
        $email,
        $profileImageUrl,
        $userType,
        '',
        '',
        '',
        '',           // uAddress, uState, city, leadUid — filled in later by the user
        $phone,
        $notificationId,                       // notification_token — set once the app registers for push
        $hash,
    ]);

    $userId = (int) $pdo->lastInsertId();

    $rawToken  = bin2hex(random_bytes(32));
    $tokenHash = hash('sha256', $rawToken);
    $expiresAt = date('Y-m-d H:i:s', strtotime('+' . TOKEN_LIFETIME_DAYS . ' days'));

    $pdo->prepare('INSERT INTO auth_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)')
        ->execute([$userId, $tokenHash, $expiresAt]);

    $pdo->commit();

    $freshStmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
    $freshStmt->execute([$userId]);
    $freshUser = $freshStmt->fetch();
    $freshUser['user_pwd'] = ''; // never return the hash

    echo json_encode([
        'success'    => true,
        'token'      => $rawToken,
        'expires_at' => $expiresAt,
        'user'       => $freshUser,
    ]);
} catch (Throwable $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Could not create account']);
}
