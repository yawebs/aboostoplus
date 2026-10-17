<?php
// submit_report.php

// TEMPORARY — remove these two lines once the error is found and fixed.
// They force PHP to show the actual error instead of a blank 500 page.
declare(strict_types=1);
ini_set('display_errors', 1);
error_reporting(E_ALL);



header('Content-Type: application/json');
require __DIR__ . '/../include/db_con.php'; // adjust the ../ depth if your folder structure differs

// How many distinct users must report the same target before it's
// auto-pulled from everyone's feed pending admin review.
const AUTO_FLAG_THRESHOLD = 3;

$input = json_decode(file_get_contents('php://input'), true);

$currentUserId = $input['user_id'] ?? null;    // the reporting user's uniqueId
$targetType    = $input['target_type'] ?? null; // 'property' | 'agent'
$targetId      = $input['target_id'] ?? null;   // houses.id (int, sent as string) OR agent's uniqueId
$reasonId      = $input['reason_id'] ?? null;
$details       = trim($input['details'] ?? '');
$evidence      = $input['evidence_urls'] ?? [];  // array of already-uploaded file URLs

// --- Validation ---
if (!is_string($currentUserId) || $currentUserId === '') {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Missing user_id']);
    exit;
}
// Confirm the user actually exists, and get their real int id — since
// content_reports.reporter_id is INT NOT NULL FOREIGN KEY -> users.id,
// not the string uniqueId the app sends.
$userCheck = $pdo->prepare('SELECT id FROM users WHERE uniqueId = ?');
$userCheck->execute([$currentUserId]);
$reporterIntId = $userCheck->fetchColumn();
if (!$reporterIntId) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unknown user']);
    exit;
}
if (!in_array($targetType, ['property', 'agent'], true)) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Invalid target_type']);
    exit;
}
if (!is_string($targetId) || $targetId === '') {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Invalid target_id']);
    exit;
}

// content_reports.target_id is also INT. For a property that's
// straightforward (houses.id is already numeric). For an agent, the
// app sends their string uniqueId (matching houses.ownerId), so we
// resolve it to the matching users.id here.
if ($targetType === 'property') {
    if (!ctype_digit($targetId)) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid property id']);
        exit;
    }
    $targetIntId = (int) $targetId;
} else {
    $agentCheck = $pdo->prepare('SELECT id FROM users WHERE uniqueId = ?');
    $agentCheck->execute([$targetId]);
    $targetIntId = $agentCheck->fetchColumn();
    if (!$targetIntId) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Agent not found']);
        exit;
    }
}

if (mb_strlen($details) < 10) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Details must be at least 10 characters']);
    exit;
}
$allowedReasons = ['misleading', 'fake', 'agent', 'scam', 'content', 'other'];
if (!in_array($reasonId, $allowedReasons, true)) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Invalid reason_id']);
    exit;
}

$caseRef = 'RPT-' . random_int(100000, 999999);

try {
    $pdo->beginTransaction();

    // 1. Log the report
    $stmt = $pdo->prepare(
        'INSERT INTO content_reports (case_ref, reporter_id, target_type, target_id, reason_id, details, evidence_urls)
         VALUES (:case_ref, :reporter_id, :target_type, :target_id, :reason_id, :details, :evidence_urls)'
    );
    $stmt->execute([
        ':case_ref'      => $caseRef,
        ':reporter_id'   => $reporterIntId,
        ':target_type'   => $targetType,
        ':target_id'     => $targetIntId,
        ':reason_id'     => $reasonId,
        ':details'       => $details,
        ':evidence_urls' => json_encode($evidence),
    ]);

    // 2. Hide immediately from the reporting user's own feed.
    // hidden_feed_items uses the original string IDs (uniqueId /
    // houses.id-as-string), matching houses.ownerId's format directly —
    // unrelated to content_reports' internal int IDs above.
    $stmt = $pdo->prepare(
        'INSERT INTO hidden_feed_items (user_id, target_type, target_id, reason)
         VALUES (:user_id, :target_type, :target_id, "reported")
         ON DUPLICATE KEY UPDATE created_at = CURRENT_TIMESTAMP'
    );
    $stmt->execute([
        ':user_id'     => $currentUserId,
        ':target_type' => $targetType,
        ':target_id'   => $targetId,
    ]);

    // 3. Count distinct reporters for this target; auto-flag if threshold hit
    $stmt = $pdo->prepare(
        'SELECT COUNT(DISTINCT reporter_id) AS n FROM content_reports
         WHERE target_type = :target_type AND target_id = :target_id'
    );
    $stmt->execute([':target_type' => $targetType, ':target_id' => $targetIntId]);
    $reportCount = (int) $stmt->fetch()['n'];

    if ($reportCount >= AUTO_FLAG_THRESHOLD) {
        if ($targetType === 'property') {
            $flag = $pdo->prepare(
                "UPDATE houses SET status = 'under_review',
                 status_reason = 'Auto-flagged: multiple reports pending admin review'
                 WHERE id = :id AND status = 'active'"
            );
            $flag->execute([':id' => $targetIntId]);
        } else {
            // $targetId here is still the agent's uniqueId string,
            // matching houses.ownerId's format.
            $flag = $pdo->prepare(
                "UPDATE users SET account_status = 'under_review'
                 WHERE uniqueId = :id AND account_status = 'active'"
            );
            $flag->execute([':id' => $targetId]);
        }
    }

    $pdo->commit();

    echo json_encode([
        'success'  => true,
        'case_ref' => $caseRef,
        'message'  => 'Report received',
    ]);
} catch (Throwable $e) {
    $pdo->rollBack();
    http_response_code(500);
    // TEMPORARY — reveals the real error so we can debug. Remove the
    // 'debug' key (or the whole catch body swap back to the generic
    // message) once this is working.
    echo json_encode([
        'success' => false,
        'message' => 'Could not submit report',
        'debug'   => $e->getMessage(),
    ]);
}
