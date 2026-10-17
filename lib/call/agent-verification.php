<?php
// Agent identity verification. Agents submit their ID, a selfie and their
// business details; an admin approves or rejects it in the admin dashboard
// (admin/index.php -> Verifications). Only approval sets users.is_verified,
// which is the ONLY thing that shows the verified badge in the app.
//
// Public:
//   POST action=lookup  ids=uid1,uid2,...   -> {success, verified: [uids]}
// Signed in (header Authorization: Bearer <token>):
//   POST action=status                      -> {success, is_verified, submission|null}
//   POST action=submit  legal_name, business_name?, office_address, state,
//                       cac_number?, id_type, id_number,
//                       id_front (image), id_back? (image), selfie (image)
//                                           -> {success, submission}
//
// ID documents are private: they are stored in uploads/verification/ behind
// a deny-all .htaccess and only admins can view them (admin/verification-file.php).
require_once __DIR__ . '/cors.php';
header('Content-Type: application/json');
ini_set('display_errors', 0);

require __DIR__ . '/../include/db_con.php';
require_once __DIR__ . '/verification_lib.php';

const AV_MAX_BYTES = 6 * 1024 * 1024;
const AV_MIME = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];

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

// Submission -> API shape. Never includes the document files themselves.
function present(array $r): array
{
    return [
        'id' => (int) $r['id'],
        'status' => $r['status'],
        'legal_name' => $r['legal_name'],
        'business_name' => $r['business_name'] ?? '',
        'office_address' => $r['office_address'],
        'state' => $r['state'],
        'cac_number' => $r['cac_number'] ?? '',
        'id_type' => $r['id_type'],
        // Only the last 4 digits go back to the phone.
        'id_number_hint' => substr((string) $r['id_number'], -4),
        'rejection_reason' => $r['rejection_reason'] ?? '',
        'created_at' => $r['created_at'],
        'reviewed_at' => $r['reviewed_at'],
    ];
}

// Saves one uploaded image into the private folder; returns its file name.
function saveDocument(string $field, bool $required): ?string
{
    $f = $_FILES[$field] ?? null;
    if (!$f || ($f['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
        if ($required) fail(avFieldLabel($field) . ' is required');
        return null;
    }
    if ($f['error'] !== UPLOAD_ERR_OK) fail(avFieldLabel($field) . ' failed to upload, please try again');
    if ($f['size'] > AV_MAX_BYTES) fail(avFieldLabel($field) . ' must be under 6MB');
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);
    if (!isset(AV_MIME[$mime])) fail(avFieldLabel($field) . ' must be a JPG, PNG or WEBP photo');

    $dir = avEnsureDir();
    if ($dir === null) fail('Could not save your documents', 500);
    $name = bin2hex(random_bytes(16)) . '.' . AV_MIME[$mime];
    if (!move_uploaded_file($f['tmp_name'], $dir . $name)) fail('Could not save your documents', 500);
    return $name;
}

function avFieldLabel(string $field): string
{
    return ['id_front' => 'The front of your ID', 'id_back' => 'The back of your ID', 'selfie' => 'Your selfie'][$field] ?? 'File';
}

$action = $_POST['action'] ?? '';

try {
    if ($action === 'lookup') {
        $ids = array_values(array_unique(array_filter(array_map('trim', explode(',', (string) ($_POST['ids'] ?? ''))))));
        $ids = array_slice($ids, 0, 200);
        if (!$ids) out(['success' => true, 'verified' => []]);
        $in = implode(',', array_fill(0, count($ids), '?'));
        $q = $pdo->prepare("SELECT uniqueId FROM users WHERE is_verified = 1 AND account_status = 'active' AND uniqueId IN ($in)");
        $q->execute($ids);
        out(['success' => true, 'verified' => $q->fetchAll(PDO::FETCH_COLUMN)]);
    }

    // Everything below needs a signed-in user.
    require __DIR__ . '/require_auth.php'; // sets $currentUserId, $currentUserUid

    $latest = function () use ($pdo, $currentUserId) {
        $q = $pdo->prepare('SELECT * FROM agent_verifications WHERE user_id = ? ORDER BY id DESC LIMIT 1');
        $q->execute([$currentUserId]);
        return $q->fetch(PDO::FETCH_ASSOC) ?: null;
    };
    $isVerified = function () use ($pdo, $currentUserId): bool {
        $q = $pdo->prepare('SELECT is_verified FROM users WHERE id = ?');
        $q->execute([$currentUserId]);
        return (int) $q->fetchColumn() === 1;
    };

    if ($action === 'status') {
        $row = $latest();
        out([
            'success' => true,
            'is_verified' => $isVerified(),
            'submission' => $row ? present($row) : null,
        ]);
    }

    if ($action === 'submit') {
        if ($isVerified()) fail('Your account is already verified');
        $row = $latest();
        if ($row && $row['status'] === 'pending') fail('Your verification is already being reviewed');

        $legal = trim($_POST['legal_name'] ?? '');
        $business = trim($_POST['business_name'] ?? '');
        $address = trim($_POST['office_address'] ?? '');
        $state = trim($_POST['state'] ?? '');
        $cac = strtoupper(preg_replace('/\s+/', '', $_POST['cac_number'] ?? ''));
        $idType = $_POST['id_type'] ?? '';
        $idNumber = strtoupper(preg_replace('/\s+/', '', $_POST['id_number'] ?? ''));

        if (mb_strlen($legal) < 4 || mb_strlen($legal) > 150) fail('Enter your full legal name as it appears on your ID');
        if (mb_strlen($business) > 150) fail('Business name is too long');
        if (mb_strlen($address) < 8 || mb_strlen($address) > 255) fail('Enter your office or business address');
        if ($state === '' || mb_strlen($state) > 60) fail('Choose your state');
        if ($cac !== '' && !preg_match('/^(RC|BN|IT)?[0-9]{4,10}$/', $cac)) fail('Enter a valid CAC number (e.g. RC1234567 or BN1234567)');
        if (!isset(AV_ID_TYPES[$idType])) fail('Choose your ID type');
        if (!preg_match(AV_ID_TYPES[$idType]['pattern'], $idNumber)) fail('Enter a valid ' . AV_ID_TYPES[$idType]['label'] . ' number');

        $front = saveDocument('id_front', true);
        $back = saveDocument('id_back', false);
        $selfie = saveDocument('selfie', true);

        $ins = $pdo->prepare('INSERT INTO agent_verifications
            (user_id, user_uid, legal_name, business_name, office_address, state, cac_number,
             id_type, id_number, id_front, id_back, selfie)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $ins->execute([
            $currentUserId, $currentUserUid, $legal, $business ?: null, $address, $state, $cac ?: null,
            $idType, $idNumber, $front, $back, $selfie,
        ]);

        out(['success' => true, 'submission' => present($latest())]);
    }

    fail('Unknown action');
} catch (Throwable $e) {
    error_log('agent-verification: ' . $e->getMessage());
    fail('Verification is unavailable right now', 500);
}
