<?php
// review_report.php
//
// Meant for an admin dashboard action. Since there's no auth/session
// service yet, this trusts admin_user_id from the request body — same
// pattern as submit_report.php. This is NOT safe to expose publicly
// as-is: anyone who knows a valid admin's uniqueId could call this and
// remove/restore listings. At minimum, keep this endpoint off any
// public-facing route until real auth is in place, and ideally put it
// behind something (IP allowlist, a shared secret header, HTTP basic
// auth on the admin folder) even as a stopgap.
declare(strict_types=1);

header('Content-Type: application/json');
require __DIR__ . '/../include/db_con.php'; // adjust the ../ depth if your folder structure differs

$input = json_decode(file_get_contents('php://input'), true);

$adminUserId = $input['admin_user_id'] ?? null;
$reportId    = $input['report_id'] ?? null;
$action      = $input['action'] ?? null; // 'actioned' | 'dismissed'

if (!is_string($adminUserId) || $adminUserId === '') {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Missing admin_user_id']);
    exit;
}
if (!is_numeric($reportId) || !in_array($action, ['actioned', 'dismissed'], true)) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Invalid input']);
    exit;
}

// Confirm the admin is a real user with userType = 'Admin', and get
// their int id — reviewed_by is INT, not the string uniqueId.
$adminCheck = $pdo->prepare("SELECT id FROM users WHERE uniqueId = ? AND userType = 'Admin'");
$adminCheck->execute([$adminUserId]);
$adminIntId = $adminCheck->fetchColumn();
if (!$adminIntId) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Not authorized']);
    exit;
}

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare('SELECT * FROM content_reports WHERE id = :id FOR UPDATE');
    $stmt->execute([':id' => $reportId]);
    $report = $stmt->fetch();

    if (!$report) {
        throw new RuntimeException('Report not found');
    }

    // Mark this report resolved
    $pdo->prepare(
        'UPDATE content_reports SET status = :status, reviewed_at = NOW(), reviewed_by = :admin WHERE id = :id'
    )->execute([
        ':status' => $action,
        ':admin'  => $adminIntId,
        ':id'     => $reportId,
    ]);

    if ($action === 'actioned') {
        if ($report['target_type'] === 'property') {
            $pdo->prepare(
                "UPDATE houses SET status = 'removed', status_reason = 'Removed after report review'
                 WHERE id = :id"
            )->execute([':id' => $report['target_id']]);
        } else {
            // $report['target_id'] here is the agent's users.id (int)
            $pdo->prepare(
                "UPDATE users SET account_status = 'suspended' WHERE id = :id"
            )->execute([':id' => $report['target_id']]);

            // houses.ownerId stores the agent's uniqueId (string), not
            // their int id, so look that up before pulling their listings.
            $uidStmt = $pdo->prepare('SELECT uniqueId FROM users WHERE id = ?');
            $uidStmt->execute([$report['target_id']]);
            $agentUid = $uidStmt->fetchColumn();

            if ($agentUid) {
                $pdo->prepare(
                    "UPDATE houses SET status = 'removed', status_reason = 'Agent suspended'
                     WHERE ownerId = :owner_id AND status != 'removed'"
                )->execute([':owner_id' => $agentUid]);
            }
        }
    } else {
        // Dismissed: if it was only auto-flagged (not yet manually removed),
        // put it back to active.
        if ($report['target_type'] === 'property') {
            $pdo->prepare(
                "UPDATE houses SET status = 'active', status_reason = NULL
                 WHERE id = :id AND status = 'under_review'"
            )->execute([':id' => $report['target_id']]);
        } else {
            $pdo->prepare(
                "UPDATE users SET account_status = 'active'
                 WHERE id = :id AND account_status = 'under_review'"
            )->execute([':id' => $report['target_id']]);
        }
    }

    $pdo->commit();
    echo json_encode(['success' => true]);
} catch (Throwable $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
