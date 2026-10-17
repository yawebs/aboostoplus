<?php
// Moving & home service providers - separate from the marketplace.
//
// Public:
//   POST action=list  category            -> {success, data: [providers]}
//   POST action=featured                  -> {success, data: [newest 12, any category]}
// Signed in (header Authorization: Bearer <token>):
//   POST action=mine                       -> {success, data: [my providers]}
//   POST action=create  business_name, category, description, state, areas,
//                       starting_price?, phone, photos[] (1-4 images)
//                                          -> {success, data: provider}
//   POST action=delete  id                 -> {success}
require_once __DIR__ . '/cors.php';
header('Content-Type: application/json');
ini_set('display_errors', 0);

require __DIR__ . '/../include/db_con.php';

const SP_CATEGORIES = [
    'Moving & Haulage', 'Cleaning', 'Painting', 'Power & Solar',
    'Plumbing', 'Electrical', 'Fumigation',
];
const SP_UPLOAD_DIR = __DIR__ . '/../uploads/services/';
const SP_UPLOAD_URL = 'https://aboostoplus.com/uploads/services/';
const SP_MAX_BYTES = 5 * 1024 * 1024;
const SP_MIME = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
const SP_MAX_PER_USER = 10;

function out(array $body, int $code = 200): void
{
    http_response_code($code);
    echo json_encode($body);
    exit;
}

function fail(string $message, int $code = 400): void
{
    out(['success' => false, 'message' => $message], $code);
}

// Row -> API shape, joined with the owner's public profile.
function present(array $r): array
{
    return [
        'id' => (int) $r['id'],
        'owner_id' => $r['owner_id'],
        'business_name' => $r['business_name'],
        'category' => $r['category'],
        'description' => $r['description'],
        'state' => $r['state'],
        'areas' => $r['areas'],
        'starting_price' => $r['starting_price'] !== null ? (float) $r['starting_price'] : null,
        'phone' => $r['phone'],
        'images' => json_decode($r['images'], true) ?: [],
        'created_at' => $r['created_at'],
        'owner_name' => trim(($r['firstname'] ?? '') . ' ' . ($r['lastname'] ?? '')),
        'owner_image' => $r['profileImage'] ?? '',
    ];
}

const SP_SELECT = 'SELECT s.*, u.firstname, u.lastname, u.profileImage
                   FROM service_providers s
                   LEFT JOIN users u ON u.uniqueId = s.owner_id';

$action = $_POST['action'] ?? '';

try {
    if ($action === 'list') {
        $category = $_POST['category'] ?? '';
        if (!in_array($category, SP_CATEGORIES, true)) fail('Unknown category');
        $q = $pdo->prepare(SP_SELECT . " WHERE s.category = ? AND s.status = 'active'
                            ORDER BY s.created_at DESC LIMIT 100");
        $q->execute([$category]);
        out(['success' => true, 'data' => array_map('present', $q->fetchAll(PDO::FETCH_ASSOC))]);
    }

    if ($action === 'featured') {
        // Newest providers across every category (home screen carousel).
        $q = $pdo->query(SP_SELECT . " WHERE s.status = 'active'
                          ORDER BY s.created_at DESC LIMIT 12");
        out(['success' => true, 'data' => array_map('present', $q->fetchAll(PDO::FETCH_ASSOC))]);
    }

    // Everything below needs a signed-in user.
    require __DIR__ . '/require_auth.php'; // sets $currentUserUid

    if ($action === 'mine') {
        $q = $pdo->prepare(SP_SELECT . ' WHERE s.owner_id = ? ORDER BY s.created_at DESC');
        $q->execute([$currentUserUid]);
        out(['success' => true, 'data' => array_map('present', $q->fetchAll(PDO::FETCH_ASSOC))]);
    }

    if ($action === 'delete') {
        $del = $pdo->prepare('DELETE FROM service_providers WHERE id = ? AND owner_id = ?');
        $del->execute([(int) ($_POST['id'] ?? 0), $currentUserUid]);
        out(['success' => $del->rowCount() > 0]);
    }

    if ($action === 'create') {
        $name = trim($_POST['business_name'] ?? '');
        $category = $_POST['category'] ?? '';
        $description = trim($_POST['description'] ?? '');
        $state = trim($_POST['state'] ?? '');
        $areas = trim($_POST['areas'] ?? '');
        $phone = preg_replace('/[^0-9+]/', '', $_POST['phone'] ?? '');
        $priceRaw = trim($_POST['starting_price'] ?? '');
        $price = $priceRaw === '' ? null : (float) str_replace(',', '', $priceRaw);

        if (mb_strlen($name) < 2 || mb_strlen($name) > 120) fail('Enter your business name');
        if (!in_array($category, SP_CATEGORIES, true)) fail('Choose a service type');
        if (mb_strlen($description) < 20) fail('Describe your service in at least 20 characters');
        if ($state === '') fail('Choose the state you work in');
        if ($areas === '') fail('List the areas you cover');
        if (strlen($phone) < 10 || strlen($phone) > 15) fail('Enter a valid phone number');
        if ($price !== null && $price < 0) fail('Enter a valid starting price');

        $count = $pdo->prepare('SELECT COUNT(*) FROM service_providers WHERE owner_id = ?');
        $count->execute([$currentUserUid]);
        if ((int) $count->fetchColumn() >= SP_MAX_PER_USER) {
            fail('You can list up to ' . SP_MAX_PER_USER . ' services. Remove one to add another.');
        }

        // Photos: photos[] multipart field, 1-4 images.
        $files = $_FILES['photos'] ?? null;
        $names = $files ? (array) $files['name'] : [];
        if (count($names) < 1) fail('Add at least one photo of your work');
        if (count($names) > 4) fail('Add up to 4 photos');
        if (!is_dir(SP_UPLOAD_DIR) && !mkdir(SP_UPLOAD_DIR, 0755, true) && !is_dir(SP_UPLOAD_DIR)) {
            fail('Could not save photos', 500);
        }
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $urls = [];
        foreach ($names as $i => $_) {
            $err = ((array) $files['error'])[$i];
            $tmp = ((array) $files['tmp_name'])[$i];
            $size = ((array) $files['size'])[$i];
            if ($err !== UPLOAD_ERR_OK) fail('A photo failed to upload, please try again');
            if ($size > SP_MAX_BYTES) fail('Each photo must be under 5MB');
            $mime = $finfo->file($tmp);
            if (!isset(SP_MIME[$mime])) fail('Photos must be JPG, PNG or WEBP images');
            $file = bin2hex(random_bytes(6)) . '_' . time() . ".$i." . SP_MIME[$mime];
            if (!move_uploaded_file($tmp, SP_UPLOAD_DIR . $file)) fail('Could not save photos', 500);
            $urls[] = SP_UPLOAD_URL . $file;
        }

        $ins = $pdo->prepare('INSERT INTO service_providers
            (owner_id, business_name, category, description, state, areas, starting_price, phone, images)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $ins->execute([$currentUserUid, $name, $category, $description, $state, $areas, $price, $phone, json_encode($urls)]);

        $q = $pdo->prepare(SP_SELECT . ' WHERE s.id = ?');
        $q->execute([(int) $pdo->lastInsertId()]);
        out(['success' => true, 'data' => present($q->fetch(PDO::FETCH_ASSOC))]);
    }

    fail('Unknown action');
} catch (Throwable $e) {
    error_log('service-providers: ' . $e->getMessage());
    fail('Services are unavailable right now', 500);
}
