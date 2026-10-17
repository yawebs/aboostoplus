<?php
// password-reset.php: forgot-password flow, by 6-digit code emailed through Resend.
//
//   POST { action: "request",  email }                     -> emails a code (same reply whether or not the email exists)
//   POST { action: "verify",   email, code }               -> { reset_token } when the code is right
//   POST { action: "complete", reset_token, password }     -> sets the password, signs out every device
//
// Table: sql/password_resets.sql. Mail config: ../include/mail_config.php.
declare(strict_types=1);

header('Content-Type: application/json');
require __DIR__ . '/../include/db_con.php';
require_once __DIR__ . '/cors.php';
require_once __DIR__ . '/mail_lib.php';

const PR_CODE_MINUTES    = 15;  // how long an emailed code works
const PR_TOKEN_MINUTES   = 15;  // how long the user has to choose a password after a correct code
const PR_MAX_ATTEMPTS    = 5;   // wrong guesses before a code is locked
const PR_RESEND_SECONDS  = 60;  // minimum gap between codes for one email
const PR_EMAIL_PER_HOUR  = 5;
const PR_IP_PER_HOUR     = 20;
const PR_MIN_PASSWORD    = 8;

function prRespond(int $status, array $body): void
{
    http_response_code($status);
    echo json_encode($body);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    prRespond(405, ['success' => false, 'message' => 'Method not allowed']);
}

$input  = json_decode(file_get_contents('php://input'), true) ?: [];
$action = $input['action'] ?? '';
$ip     = substr((string) ($_SERVER['REMOTE_ADDR'] ?? ''), 0, 45);

try {
    switch ($action) {
        case 'request':  prRequest($pdo, $input, $ip);
        case 'verify':   prVerify($pdo, $input);
        case 'complete': prComplete($pdo, $input);
        default:         prRespond(400, ['success' => false, 'message' => 'Unknown action']);
    }
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('password-reset.php: ' . $e->getMessage());
    prRespond(500, ['success' => false, 'message' => 'Something went wrong. Please try again.']);
}

// Step 1: email a fresh code. The reply never says whether the account exists,
// matching login.php, so the endpoint can't be used to discover who is registered.
function prRequest(PDO $pdo, array $input, string $ip): void
{
    $email = strtolower(trim((string) ($input['email'] ?? '')));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        prRespond(422, ['success' => false, 'message' => 'Enter a valid email address']);
    }

    $q = $pdo->prepare('SELECT COUNT(*) FROM password_resets WHERE request_ip = ? AND created_at > NOW() - INTERVAL 1 HOUR');
    $q->execute([$ip]);
    if ((int) $q->fetchColumn() >= PR_IP_PER_HOUR) {
        prRespond(429, ['success' => false, 'message' => 'Too many requests. Please try again later.']);
    }

    $generic = ['success' => true, 'message' => "If an account exists for $email, we've sent a 6-digit code to it."];

    $q = $pdo->prepare('SELECT id, firstname, account_status FROM users WHERE email = ? LIMIT 1');
    $q->execute([$email]);
    $user = $q->fetch(PDO::FETCH_ASSOC);
    if (!$user || $user['account_status'] !== 'active') {
        prRespond(200, $generic);
    }

    // Throttle per email. The previous code is still valid, so the user loses nothing.
    $q = $pdo->prepare(
        'SELECT COUNT(*) AS hour_count,
                COALESCE(MAX(created_at) > NOW() - INTERVAL ' . PR_RESEND_SECONDS . ' SECOND, 0) AS too_soon
           FROM password_resets WHERE email = ? AND created_at > NOW() - INTERVAL 1 HOUR'
    );
    $q->execute([$email]);
    $recent = $q->fetch(PDO::FETCH_ASSOC);
    if ((int) $recent['too_soon'] === 1 || (int) $recent['hour_count'] >= PR_EMAIL_PER_HOUR) {
        prRespond(200, $generic);
    }

    $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

    // Only the newest code works.
    $pdo->prepare('UPDATE password_resets SET used_at = NOW() WHERE user_id = ? AND used_at IS NULL')
        ->execute([$user['id']]);
    $pdo->prepare(
        'INSERT INTO password_resets (user_id, email, code_hash, expires_at, request_ip)
         VALUES (?, ?, ?, NOW() + INTERVAL ' . PR_CODE_MINUTES . ' MINUTE, ?)'
    )->execute([$user['id'], $email, password_hash($code, PASSWORD_DEFAULT), $ip]);

    [$html, $text] = mailPasswordResetCode((string) $user['firstname'], $code, PR_CODE_MINUTES);
    if (!resendSend($email, "$code is your Aboostoplus reset code", $html, $text)) {
        prRespond(502, ['success' => false, 'message' => "We couldn't send the email right now. Please try again in a few minutes."]);
    }

    prRespond(200, $generic);
}

// Step 2: check the code; a correct one is exchanged for a single-use reset token.
function prVerify(PDO $pdo, array $input): void
{
    $email = strtolower(trim((string) ($input['email'] ?? '')));
    $code  = preg_replace('/\D/', '', (string) ($input['code'] ?? ''));
    if ($email === '' || strlen($code) !== 6) {
        prRespond(422, ['success' => false, 'message' => 'Enter the 6-digit code from the email']);
    }

    $q = $pdo->prepare(
        'SELECT id, code_hash, attempts, expires_at > NOW() AS live
           FROM password_resets
          WHERE email = ? AND used_at IS NULL AND reset_token_hash IS NULL
          ORDER BY id DESC LIMIT 1'
    );
    $q->execute([$email]);
    $row = $q->fetch(PDO::FETCH_ASSOC);

    if (!$row || (int) $row['live'] !== 1) {
        prRespond(400, ['success' => false, 'code' => 'expired', 'message' => 'This code has expired. Request a new one.']);
    }
    if ((int) $row['attempts'] >= PR_MAX_ATTEMPTS) {
        prRespond(429, ['success' => false, 'code' => 'locked', 'message' => 'Too many wrong attempts. Request a new code.']);
    }
    if (!password_verify($code, $row['code_hash'])) {
        $pdo->prepare('UPDATE password_resets SET attempts = attempts + 1 WHERE id = ?')->execute([$row['id']]);
        $left = PR_MAX_ATTEMPTS - (int) $row['attempts'] - 1;
        prRespond(400, [
            'success' => false,
            'code'    => $left > 0 ? 'wrong' : 'locked',
            'message' => $left > 0
                ? "That code isn't right. $left " . ($left === 1 ? 'attempt' : 'attempts') . ' left.'
                : 'Too many wrong attempts. Request a new code.',
        ]);
    }

    $token = bin2hex(random_bytes(32));
    $pdo->prepare(
        'UPDATE password_resets
            SET reset_token_hash = ?, reset_token_expires = NOW() + INTERVAL ' . PR_TOKEN_MINUTES . ' MINUTE
          WHERE id = ?'
    )->execute([hash('sha256', $token), $row['id']]);

    prRespond(200, ['success' => true, 'reset_token' => $token]);
}

// Step 3: set the new password, close the reset and sign out every device.
function prComplete(PDO $pdo, array $input): void
{
    $token    = (string) ($input['reset_token'] ?? '');
    $password = (string) ($input['password'] ?? '');
    if (strlen($password) < PR_MIN_PASSWORD || strlen($password) > 128) {
        prRespond(422, ['success' => false, 'message' => 'Password must be at least ' . PR_MIN_PASSWORD . ' characters']);
    }

    $q = $pdo->prepare(
        'SELECT pr.id, pr.user_id, pr.email, u.firstname
           FROM password_resets pr JOIN users u ON u.id = pr.user_id
          WHERE pr.reset_token_hash = ? AND pr.used_at IS NULL AND pr.reset_token_expires > NOW()
          LIMIT 1'
    );
    $q->execute([hash('sha256', $token)]);
    $row = $q->fetch(PDO::FETCH_ASSOC);
    if ($token === '' || !$row) {
        prRespond(400, ['success' => false, 'code' => 'expired', 'message' => 'This reset session has expired. Please start again.']);
    }

    $pdo->beginTransaction();
    // Same hashing as register.php, so login.php's password_verify keeps working.
    $pdo->prepare('UPDATE users SET user_pwd = ? WHERE id = ?')
        ->execute([password_hash($password, PASSWORD_BCRYPT), $row['user_id']]);
    $pdo->prepare('UPDATE password_resets SET used_at = NOW() WHERE user_id = ? AND used_at IS NULL')
        ->execute([$row['user_id']]);
    $pdo->prepare('DELETE FROM auth_tokens WHERE user_id = ?')->execute([$row['user_id']]);
    $pdo->commit();

    [$html, $text] = mailPasswordChanged((string) $row['firstname']);
    resendSend($row['email'], 'Your Aboostoplus password was changed', $html, $text); // best effort

    prRespond(200, ['success' => true, 'message' => 'Your password has been updated. Sign in with your new password.']);
}
