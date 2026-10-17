<?php
// logout.php
declare(strict_types=1);

header('Content-Type: application/json');
require __DIR__ . '/../include/db_con.php';

$headers = function_exists('getallheaders') ? getallheaders() : [];
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

if (preg_match('/^Bearer\s+(.+)$/i', $authHeader, $m)) {
    $tokenHash = hash('sha256', trim($m[1]));
    $pdo->prepare('DELETE FROM auth_tokens WHERE token_hash = ?')->execute([$tokenHash]);
}

// Always return success — whether or not a token was found, the end
// state the client wants (logged out) is achieved either way.
echo json_encode(['success' => true]);
