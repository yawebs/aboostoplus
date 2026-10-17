<?php
// require_auth.php
//
// Include this AFTER db_con.php in any endpoint that needs a logged-in
// user. On success it sets:
//   $currentUserId   -> users.id       (int)    — use for FK columns
//   $currentUserUid  -> users.uniqueId (string) — use for houses.ownerId matches
//   $currentUserType -> users.userType (string) — e.g. 'Agent', 'User', 'Admin'
// On failure it sends a 401 JSON response and exits — nothing after the
// require runs.

$headers = function_exists('getallheaders') ? getallheaders() : [];
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $m)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Missing or invalid Authorization header']);
    exit;
}

$rawToken = trim($m[1]);
$tokenHash = hash('sha256', $rawToken);

$stmt = $pdo->prepare(
    'SELECT u.id, u.uniqueId, u.userType, u.account_status
     FROM auth_tokens t
     INNER JOIN users u ON u.id = t.user_id
     WHERE t.token_hash = ? AND t.expires_at > NOW()'
);
$stmt->execute([$tokenHash]);
$row = $stmt->fetch();

if (!$row) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid or expired session']);
    exit;
}

if ($row['account_status'] !== 'active') {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Account is ' . $row['account_status']]);
    exit;
}

$currentUserId   = (int) $row['id'];
$currentUserUid  = $row['uniqueId'];
$currentUserType = $row['userType'];

// Best-effort activity timestamp — don't fail the request if this errors
try {
    $pdo->prepare('UPDATE auth_tokens SET last_used_at = NOW() WHERE token_hash = ?')
        ->execute([$tokenHash]);
} catch (Throwable $e) {
    // ignore
}
