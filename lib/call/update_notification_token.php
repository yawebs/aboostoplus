<?php
// update_notification_token.php
declare(strict_types=1);

header('Content-Type: application/json');
require __DIR__ . '/../include/db_con.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'POST required']);
    exit;
}

$userId = trim($_POST['user_id'] ?? '');       // your uniqueId, matching users.uniqueId
$token  = trim($_POST['notification_token'] ?? '');

if ($userId === '' || $token === '') {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'user_id and notification_token are required']);
    exit;
}

try {
    $stmt = $pdo->prepare('UPDATE users SET notification_token = ? WHERE uniqueId = ?');
    $stmt->execute([$token, $userId]);

    echo json_encode(['success' => true, 'updated' => $stmt->rowCount() > 0]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Could not update token']);
}
