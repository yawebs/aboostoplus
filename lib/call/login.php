<?php
// login.php
declare(strict_types=1);

header('Content-Type: application/json');
require __DIR__ . '/../include/db_con.php';

require_once __DIR__ . '/cors.php';
// ... existing login.php code continues unchanged below


const TOKEN_LIFETIME_DAYS = 30;

$input = json_decode(file_get_contents('php://input'), true);

$email    = trim($input['email'] ?? '');
$password = $input['password'] ?? '';

if ($email === '' || $password === '') {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Email and password are required']);
    exit;
}

$stmt = $pdo->prepare('SELECT * FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

// Same generic message for "no such user" and "wrong password" —
// specific messages let an attacker enumerate which emails are registered.
if (!$user || !password_verify($password, $user['user_pwd'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid email or password']);
    exit;
}

if ($user['account_status'] !== 'active') {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Account is ' . $user['account_status']]);
    exit;
}

$rawToken  = bin2hex(random_bytes(32));
$tokenHash = hash('sha256', $rawToken);
$expiresAt = date('Y-m-d H:i:s', strtotime('+' . TOKEN_LIFETIME_DAYS . ' days'));

$pdo->prepare('INSERT INTO auth_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)')
    ->execute([$user['id'], $tokenHash, $expiresAt]);

// Strip the password hash before sending anything back to the client —
// never return it, even hashed. Keep the key present (as an empty
// string) so UserModel.fromDoc(...) still works without modification,
// since its constructor requires `password`.
$user['user_pwd'] = '';

echo json_encode([
    'success'    => true,
    'token'      => $rawToken,
    'expires_at' => $expiresAt,
    // Matches raw `SELECT * FROM users` column names exactly, so the
    // Flutter side can build this straight into UserModel.fromDoc(...).
    'user'       => $user,
]);
