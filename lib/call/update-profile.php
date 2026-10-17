<?php
// Edit profile for the signed-in user (identified by their auth token, so a
// request can only ever change its own account).
//
// POST multipart/form-data, header  Authorization: Bearer <token>
//   first_name, last_name, phone, address, state, city   (text)
//   profileImage                                         (optional file)
// -> {success: true, data: <users row>} | {success: false, message}
require_once __DIR__ . '/cors.php';
header('Content-Type: application/json');
ini_set('display_errors', 0);

require __DIR__ . '/../include/db_con.php';
require __DIR__ . '/require_auth.php'; // sets $currentUserId / $currentUserUid

const PROFILE_UPLOAD_DIR = __DIR__ . '/../uploads/';
const PROFILE_UPLOAD_URL = 'https://aboostoplus.com/uploads/';
const PROFILE_MAX_BYTES = 5 * 1024 * 1024;
const PROFILE_MIME = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];

function fail(string $message, int $code = 400): void
{
    http_response_code($code);
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
}

// Optional new photo -> public URL, or null if none was sent.
function saveProfilePhoto(): ?string
{
    if (!isset($_FILES['profileImage']) || $_FILES['profileImage']['error'] === UPLOAD_ERR_NO_FILE) {
        return null;
    }
    $file = $_FILES['profileImage'];
    if ($file['error'] !== UPLOAD_ERR_OK) fail('Photo upload failed, please try again');
    if ($file['size'] > PROFILE_MAX_BYTES) fail('Photo must be under 5MB');

    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
    if (!isset(PROFILE_MIME[$mime])) fail('Photo must be a JPG, PNG or WEBP image');

    if (!is_dir(PROFILE_UPLOAD_DIR) && !mkdir(PROFILE_UPLOAD_DIR, 0755, true) && !is_dir(PROFILE_UPLOAD_DIR)) {
        fail('Could not save photo', 500);
    }
    $name = bin2hex(random_bytes(6)) . '_' . time() . '.' . PROFILE_MIME[$mime];
    if (!move_uploaded_file($file['tmp_name'], PROFILE_UPLOAD_DIR . $name)) {
        fail('Could not save photo', 500);
    }
    return PROFILE_UPLOAD_URL . $name;
}

$first = trim($_POST['first_name'] ?? '');
$last = trim($_POST['last_name'] ?? '');
$phone = preg_replace('/[^0-9+]/', '', $_POST['phone'] ?? '');
$address = trim($_POST['address'] ?? '');
$state = trim($_POST['state'] ?? '');
$city = trim($_POST['city'] ?? '');

if ($first === '' || mb_strlen($first) > 60) fail('Please enter your first name');
if ($last === '' || mb_strlen($last) > 60) fail('Please enter your last name');
if ($phone !== '' && (strlen($phone) < 10 || strlen($phone) > 15)) fail('Please enter a valid phone number');
if (mb_strlen($address) > 200) fail('Address is too long');

try {
    $photo = saveProfilePhoto();

    $sql = 'UPDATE users SET firstname = ?, lastname = ?, phone = ?, uAddress = ?, uState = ?, city = ?';
    $params = [$first, $last, $phone, $address, $state, $city];
    if ($photo !== null) {
        $sql .= ', profileImage = ?';
        $params[] = $photo;
    }
    $sql .= ' WHERE id = ?';
    $params[] = $currentUserId;
    $pdo->prepare($sql)->execute($params);

    $q = $pdo->prepare('SELECT * FROM users WHERE id = ? LIMIT 1');
    $q->execute([$currentUserId]);
    $user = $q->fetch(PDO::FETCH_ASSOC);
    unset($user['user_pwd']); // never send the password hash back

    echo json_encode(['success' => true, 'data' => $user]);
} catch (Throwable $e) {
    error_log('update-profile: ' . $e->getMessage());
    fail('Could not update your profile right now', 500);
}
