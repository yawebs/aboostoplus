<?php
// delete-account.php: permanently deletes the signed-in user's account.
//
//   POST { confirm: "DELETE" }  with  Authorization: Bearer <token>
//
// Listings are taken down, personal data and uploaded verification documents
// are deleted, and the users row is anonymised (kept only so chat threads and
// deals other people are part of don't break). The account can't be signed into again.
declare(strict_types=1);

header('Content-Type: application/json');
require __DIR__ . '/../include/db_con.php';
require_once __DIR__ . '/cors.php';
require __DIR__ . '/require_auth.php';
require_once __DIR__ . '/verification_lib.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true) ?: [];
if (($input['confirm'] ?? '') !== 'DELETE') {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Please confirm that you want to delete your account']);
    exit;
}

// Tables added by later migrations may not exist on every database; skip those quietly.
function daRun(PDO $pdo, string $sql, array $params): void
{
    try {
        $pdo->prepare($sql)->execute($params);
    } catch (PDOException $e) {
        if ($e->getCode() !== '42S02') { // 42S02 = table doesn't exist
            throw $e;
        }
    }
}

$id  = $currentUserId;
$uid = $currentUserUid;

try {
    // Collect verification document file names before their rows go.
    $files = [];
    try {
        $q = $pdo->prepare('SELECT id_front, id_back, selfie FROM agent_verifications WHERE user_id = ?');
        $q->execute([$id]);
        foreach ($q->fetchAll(PDO::FETCH_ASSOC) as $row) {
            foreach ($row as $f) {
                if ($f) $files[] = basename((string) $f);
            }
        }
    } catch (PDOException $e) {
        if ($e->getCode() !== '42S02') throw $e;
    }

    $pdo->beginTransaction();

    daRun($pdo, "UPDATE houses SET status = 'removed', status_reason = 'Owner deleted their account' WHERE ownerId = ?", [$uid]);
    daRun($pdo, 'DELETE FROM market_place WHERE ownerId = ?', [$uid]);
    daRun($pdo, 'DELETE FROM service_providers WHERE owner_id = ?', [$uid]);
    // These two store either users.id or users.uniqueId depending on app version.
    daRun($pdo, 'DELETE FROM saved_properties WHERE user_id IN (?, ?)', [(string) $id, $uid]);
    daRun($pdo, 'DELETE FROM search_alerts WHERE user_id IN (?, ?)', [(string) $id, $uid]);
    daRun($pdo, 'DELETE FROM agent_verifications WHERE user_id = ?', [$id]);
    daRun($pdo, 'DELETE FROM social_identities WHERE user_id = ?', [$id]);
    daRun($pdo, 'DELETE FROM password_resets WHERE user_id = ?', [$id]);

    $pdo->prepare(
        "UPDATE users SET
            firstname = 'Deleted', lastname = 'user', email = ?, phone = '', profileImage = '',
            uAddress = '', notification_token = '', user_pwd = '', account_status = 'deleted'
         WHERE id = ?"
    )->execute(["deleted-$id@deleted.aboostoplus.invalid", $id]);
    daRun($pdo, 'UPDATE users SET is_verified = 0, verified_at = NULL WHERE id = ?', [$id]);

    // Signs the account out everywhere, including this request's session.
    $pdo->prepare('DELETE FROM auth_tokens WHERE user_id = ?')->execute([$id]);

    $pdo->commit();
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('delete-account.php: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'We could not delete your account right now. Please try again or email support@aboostoplus.com.']);
    exit;
}

// ID photos and selfies are deleted outright once the database change is committed.
foreach ($files as $f) {
    $path = AV_DIR . $f;
    if (is_file($path)) {
        @unlink($path);
    }
}

echo json_encode(['success' => true, 'message' => 'Your account has been deleted.']);
