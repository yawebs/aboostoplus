<?php
// actions.php — single POST endpoint for every mutation the admin dashboard
// triggers (user moderation, property moderation, report review, deal
// status). Mirrors the logic already used in review_report.php but runs
// under an authenticated admin session instead of a trusted client-sent id.
declare(strict_types=1);

require __DIR__ . '/auth.php';
requireAdmin();
require __DIR__ . '/../../include/db_con.php';

$tab = $_POST['tab'] ?? 'overview';

function back(string $tab, string $type, string $msg): void
{
    header('Location: index.php?tab=' . urlencode($tab) . '&type=' . urlencode($type) . '&msg=' . urlencode($msg));
    exit;
}

if (!verifyCsrf($_POST['csrf'] ?? null)) {
    back($tab, 'danger', 'Your session expired, please try again.');
}

$action = $_POST['action'] ?? '';
$id = $_POST['id'] ?? '';
$decision = $_POST['decision'] ?? '';

try {
    switch ($action) {

        case 'suspend_user': {
            $userId = (int) $id;
            $uidStmt = $pdo->prepare('SELECT uniqueId FROM users WHERE id = ?');
            $uidStmt->execute([$userId]);
            $uid = $uidStmt->fetchColumn();

            $pdo->prepare("UPDATE users SET account_status = 'suspended' WHERE id = ?")->execute([$userId]);
            if ($uid) {
                $pdo->prepare(
                    "UPDATE houses SET status = 'removed', status_reason = 'Owner suspended by admin'
                     WHERE ownerId = ? AND status != 'removed'"
                )->execute([$uid]);
            }
            back('users', 'success', 'User suspended.');
        }

        case 'activate_user': {
            $userId = (int) $id;
            $uidStmt = $pdo->prepare('SELECT uniqueId FROM users WHERE id = ?');
            $uidStmt->execute([$userId]);
            $uid = $uidStmt->fetchColumn();

            $pdo->prepare("UPDATE users SET account_status = 'active' WHERE id = ?")->execute([$userId]);
            if ($uid) {
                $pdo->prepare(
                    "UPDATE houses SET status = 'active', status_reason = NULL
                     WHERE ownerId = ? AND status = 'under_review'"
                )->execute([$uid]);
            }
            back('users', 'success', 'User re-activated.');
        }

        case 'delete_user': {
            $userId = (int) $id;
            $pdo->beginTransaction();
            $pdo->prepare('DELETE FROM auth_tokens WHERE user_id = ?')->execute([$userId]);
            $pdo->prepare('DELETE FROM users WHERE id = ?')->execute([$userId]);
            $pdo->commit();
            back('users', 'success', 'User removed.');
        }

        case 'remove_property': {
            $pdo->prepare(
                "UPDATE houses SET status = 'removed', status_reason = 'Removed by admin' WHERE id = ?"
            )->execute([(int) $id]);
            back('properties', 'success', 'Listing removed.');
        }

        case 'restore_property': {
            $pdo->prepare(
                "UPDATE houses SET status = 'active', status_reason = NULL WHERE id = ?"
            )->execute([(int) $id]);
            back('properties', 'success', 'Listing restored.');
        }

        case 'delete_property': {
            $pdo->prepare('DELETE FROM houses WHERE id = ?')->execute([(int) $id]);
            back('properties', 'success', 'Listing deleted permanently.');
        }

        case 'delete_product': {
            $pdo->prepare('DELETE FROM market_place WHERE id = ?')->execute([(int) $id]);
            back('products', 'success', 'Product deleted permanently.');
        }

        case 'send_notification': {
            $audience = $_POST['audience'] ?? '';
            $title = trim($_POST['title'] ?? '');
            $body = trim($_POST['body'] ?? '');
            $targetUserId = $_POST['user_id'] ?? '';

            if ($title === '' || $body === '') {
                back('notifications', 'danger', 'Title and message are both required.');
            }
            if (!in_array($audience, ['all', 'agents', 'users', 'single'], true)) {
                back('notifications', 'danger', 'Invalid audience.');
            }

            if ($audience === 'single') {
                if ($targetUserId === '') {
                    back('notifications', 'danger', 'Pick a user to notify.');
                }
                $stmt = $pdo->prepare(
                    "SELECT notification_token FROM users
                     WHERE uniqueId = ? AND notification_token IS NOT NULL AND notification_token <> '' AND account_status = 'active'"
                );
                $stmt->execute([$targetUserId]);
            } else {
                $sql = "SELECT notification_token FROM users
                        WHERE notification_token IS NOT NULL AND notification_token <> '' AND account_status = 'active'";
                if ($audience === 'agents') {
                    $sql .= " AND userType = 'Agent'";
                } elseif ($audience === 'users') {
                    $sql .= " AND userType = 'User'";
                }
                $stmt = $pdo->query($sql);
            }

            $tokens = $stmt->fetchAll(PDO::FETCH_COLUMN);

            if (!$tokens) {
                back('notifications', 'danger', 'No reachable recipients — nobody in that group has a registered device.');
            }

            try {
                set_time_limit(120);
                require_once __DIR__ . '/../../include/vendor/autoload.php';
                require_once __DIR__ . '/../FcmNotificationSender.php';

                $credentialsPath = __DIR__ . '/../../include/firebase_credentials.json';
                $serviceAccount = json_decode(file_get_contents($credentialsPath), true);

                $sender = new FcmNotificationSender($serviceAccount['project_id'], $credentialsPath);
                $results = $sender->sendToMultipleDevices($tokens, $title, $body, ['type' => 'admin_broadcast']);

                $failed = 0;
                foreach ($results as $result) {
                    if (isset($result['error'])) {
                        $failed++;
                    }
                }
                $sent = count($tokens) - $failed;

                $msg = "Notification sent to {$sent} device(s).";
                if ($failed > 0) {
                    $msg .= " {$failed} failed to deliver.";
                }
                back('notifications', $sent > 0 ? 'success' : 'danger', $msg);
            } catch (Throwable $e) {
                back('notifications', 'danger', 'Could not send notification: ' . $e->getMessage());
            }
        }

        case 'send_email': {
            require_once __DIR__ . '/../mail_lib.php';
            $audience = $_POST['audience'] ?? '';
            $subject  = trim($_POST['subject'] ?? '');
            $message  = trim($_POST['message'] ?? '');
            $ctaLabel = trim($_POST['cta_label'] ?? '');
            $ctaUrl   = trim($_POST['cta_url'] ?? '');
            $testOnly = !empty($_POST['test_only']);

            if ($subject === '' || $message === '') {
                back('emails', 'danger', 'Subject and message are both required.');
            }
            if (!in_array($audience, ['all', 'agents', 'users', 'single'], true)) {
                back('emails', 'danger', 'Invalid audience.');
            }
            if (($ctaLabel === '') !== ($ctaUrl === '') || ($ctaUrl !== '' && !preg_match('#^https://#i', $ctaUrl))) {
                back('emails', 'danger', 'For a button, give both a label and a link starting with https://');
            }
            if (mailConfig() === null) {
                back('emails', 'danger', 'Email is not set up: add your Resend key to include/mail_config.php.');
            }

            if ($testOnly) {
                // Preview: send to the signed-in admin only.
                $me = $pdo->prepare('SELECT id, firstname, email FROM users WHERE id = ?');
                $me->execute([(int) $_SESSION['admin_id']]);
                $recipients = $me->fetchAll();
            } elseif ($audience === 'single') {
                $one = $pdo->prepare("SELECT id, firstname, email FROM users WHERE id = ? AND email <> '' AND account_status = 'active'");
                $one->execute([(int) ($_POST['user_id'] ?? 0)]);
                $recipients = $one->fetchAll();
            } else {
                // Broadcasts skip suspended/deleted accounts and anyone who unsubscribed.
                $sql = "SELECT id, firstname, email FROM users
                        WHERE email <> '' AND email NOT LIKE '%@deleted.aboostoplus.invalid' AND account_status = 'active'
                          AND userType <> 'Admin' AND email_opt_out = 0";
                if ($audience === 'agents') $sql .= " AND userType = 'Agent'";
                if ($audience === 'users')  $sql .= " AND userType = 'User'";
                try {
                    $recipients = $pdo->query($sql)->fetchAll();
                } catch (PDOException $e) {
                    back('emails', 'danger', 'Run lib/call/sql/admin_emails.sql on the database first, so unsubscribes are respected.');
                }
            }
            $recipients = array_values(array_filter($recipients, fn($r) => filter_var($r['email'], FILTER_VALIDATE_EMAIL)));
            if (!$recipients) {
                back('emails', 'danger', 'No one to send to: nobody in that group has a valid email address.');
            }

            set_time_limit(600);
            $bulk = !$testOnly && $audience !== 'single';
            $emails = [];
            foreach ($recipients as $r) {
                $unsub = $bulk ? mailUnsubscribeUrl((int) $r['id']) : '';
                [$subj, $html, $text] = mailAdminMessage((string) $r['firstname'], $subject, $message, $ctaLabel, $ctaUrl, $unsub);
                $email = ['to' => $r['email'], 'subject' => ($testOnly ? '[TEST] ' : '') . $subj, 'html' => $html, 'text' => $text];
                if ($unsub !== '') {
                    $email['headers'] = ['List-Unsubscribe' => "<$unsub>", 'List-Unsubscribe-Post' => 'List-Unsubscribe=One-Click'];
                }
                $emails[] = $email;
            }
            $result = resendSendBatch($emails);

            try {
                $pdo->prepare('INSERT INTO admin_email_log (admin_id, admin_name, audience, subject, recipients, sent, failed) VALUES (?, ?, ?, ?, ?, ?, ?)')
                    ->execute([(int) $_SESSION['admin_id'], currentAdminName(), $testOnly ? 'test' : $audience, mb_substr($subject, 0, 200), count($emails), $result['sent'], $result['failed']]);
            } catch (Throwable $e) {
                // log table not created yet; sending still worked
            }

            if ($testOnly) {
                back('emails', $result['sent'] ? 'success' : 'danger', $result['sent'] ? 'Test email sent to ' . $recipients[0]['email'] . '.' : 'The test email could not be sent. Check the Resend key and domain.');
            }
            $msg = "Email sent to {$result['sent']} " . ($result['sent'] === 1 ? 'person' : 'people') . '.';
            if ($result['failed'] > 0) $msg .= " {$result['failed']} failed. Check the Resend dashboard for details.";
            back('emails', $result['sent'] > 0 ? 'success' : 'danger', $msg);
        }

        case 'approve_verification':
        case 'reject_verification': {
            require_once __DIR__ . '/../verification_lib.php';
            $approve = $action === 'approve_verification';
            $reason = trim($_POST['reason'] ?? '');
            if (!$approve && $reason === '') {
                back('verifications', 'danger', 'Tell the agent why it was rejected so they can fix it.');
            }

            $pdo->beginTransaction();
            $stmt = $pdo->prepare("SELECT * FROM agent_verifications WHERE id = ? FOR UPDATE");
            $stmt->execute([(int) $id]);
            $sub = $stmt->fetch();
            if (!$sub || $sub['status'] !== 'pending') {
                $pdo->rollBack();
                back('verifications', 'danger', 'That request was already reviewed.');
            }

            $pdo->prepare(
                'UPDATE agent_verifications SET status = ?, rejection_reason = ?, reviewed_at = NOW(), reviewed_by = ? WHERE id = ?'
            )->execute([$approve ? 'approved' : 'rejected', $approve ? null : mb_substr($reason, 0, 500), (int) $_SESSION['admin_id'], (int) $id]);
            if ($approve) {
                $pdo->prepare('UPDATE users SET is_verified = 1, verified_at = NOW() WHERE id = ?')
                    ->execute([(int) $sub['user_id']]);
            }
            $pdo->commit();

            if ($approve) {
                avNotifyUser($pdo, (int) $sub['user_id'], "You're verified!",
                    'Your verified badge is now live on your profile and listings.');
            } else {
                avNotifyUser($pdo, (int) $sub['user_id'], 'Verification needs another look',
                    $reason . ' Open Aboostoplus to resubmit.');
            }
            back('verifications', 'success', $approve ? 'Agent verified - their badge is live.' : 'Verification rejected and the agent was notified.');
        }

        case 'revoke_verification': {
            $pdo->prepare('UPDATE users SET is_verified = 0, verified_at = NULL WHERE id = ?')->execute([(int) $id]);
            back('verifications', 'success', 'Verification removed - the badge no longer shows.');
        }

        case 'update_deal_status': {
            if (!in_array($decision, ['Completed', 'Cancelled'], true)) {
                back('inspections', 'danger', 'Invalid status.');
            }
            $pdo->prepare('UPDATE deals_tbl SET dealStatus = ? WHERE id = ?')->execute([$decision, (int) $id]);
            back('inspections', 'success', 'Inspection marked as ' . $decision . '.');
        }

        case 'review_report': {
            if (!in_array($decision, ['actioned', 'dismissed'], true)) {
                back('reports', 'danger', 'Invalid decision.');
            }
            $reportId = (int) $id;
            $adminIntId = (int) $_SESSION['admin_id'];

            $pdo->beginTransaction();

            $stmt = $pdo->prepare('SELECT * FROM content_reports WHERE id = ? FOR UPDATE');
            $stmt->execute([$reportId]);
            $report = $stmt->fetch();

            if (!$report) {
                throw new RuntimeException('Report not found');
            }

            $pdo->prepare(
                'UPDATE content_reports SET status = ?, reviewed_at = NOW(), reviewed_by = ? WHERE id = ?'
            )->execute([$decision, $adminIntId, $reportId]);

            if ($decision === 'actioned') {
                if ($report['target_type'] === 'property') {
                    $pdo->prepare(
                        "UPDATE houses SET status = 'removed', status_reason = 'Removed after report review'
                         WHERE id = ?"
                    )->execute([$report['target_id']]);
                } else {
                    $pdo->prepare("UPDATE users SET account_status = 'suspended' WHERE id = ?")
                        ->execute([$report['target_id']]);

                    $uidStmt = $pdo->prepare('SELECT uniqueId FROM users WHERE id = ?');
                    $uidStmt->execute([$report['target_id']]);
                    $agentUid = $uidStmt->fetchColumn();

                    if ($agentUid) {
                        $pdo->prepare(
                            "UPDATE houses SET status = 'removed', status_reason = 'Agent suspended'
                             WHERE ownerId = ? AND status != 'removed'"
                        )->execute([$agentUid]);
                    }
                }
            } else {
                if ($report['target_type'] === 'property') {
                    $pdo->prepare(
                        "UPDATE houses SET status = 'active', status_reason = NULL
                         WHERE id = ? AND status = 'under_review'"
                    )->execute([$report['target_id']]);
                } else {
                    $pdo->prepare(
                        "UPDATE users SET account_status = 'active'
                         WHERE id = ? AND account_status = 'under_review'"
                    )->execute([$report['target_id']]);
                }
            }

            $pdo->commit();
            back('reports', 'success', 'Report ' . $decision . '.');
        }

        default:
            back($tab, 'danger', 'Unknown action.');
    }
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    back($tab, 'danger', 'Action failed: ' . $e->getMessage());
}
