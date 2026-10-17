<?php
// Who reacted to a property, with each person's public profile.
//   POST propertyId -> {success, data: [{user_id, name, image, user_type, reaction: up|down}]}
// Thumbs up first. Never returns contact details.
require_once __DIR__ . '/cors.php';
header('Content-Type: application/json');
ini_set('display_errors', 0);

require __DIR__ . '/../include/db_con.php';

$propertyId = (int) ($_POST['propertyId'] ?? 0);
if ($propertyId <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing property']);
    exit;
}

try {
    $q = $pdo->prepare(
        "SELECT t.userId, t.userName, t.thumb_up, t.thumb_down,
                u.firstname, u.lastname, u.profileImage, u.userType
         FROM thumps_up_tbl t
         LEFT JOIN users u ON u.uniqueId = t.userId
         WHERE t.propertyId = ? AND (t.thumb_up = 1 OR t.thumb_down = 1)
           AND (u.account_status IS NULL OR u.account_status = 'active')
         ORDER BY t.thumb_up DESC
         LIMIT 500"
    );
    $q->execute([$propertyId]);

    $data = [];
    foreach ($q->fetchAll(PDO::FETCH_ASSOC) as $r) {
        $name = trim(($r['firstname'] ?? '') . ' ' . ($r['lastname'] ?? ''));
        $data[] = [
            'user_id' => (string) $r['userId'],
            'name' => $name !== '' ? $name : ((string) ($r['userName'] ?? '') ?: 'Aboostoplus user'),
            'image' => (string) ($r['profileImage'] ?? ''),
            'user_type' => (string) ($r['userType'] ?? ''),
            'reaction' => (int) $r['thumb_up'] === 1 ? 'up' : 'down',
        ];
    }
    echo json_encode(['success' => true, 'data' => $data]);
} catch (Throwable $e) {
    error_log('reactions-list: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Reactions are unavailable right now']);
}
