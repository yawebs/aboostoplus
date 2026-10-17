<?php
// Shared by agent-verification.php and the admin dashboard.

const AV_DIR = __DIR__ . '/../uploads/verification/';

const AV_ID_TYPES = [
    'nin'             => ['label' => 'NIN',                   'pattern' => '/^[0-9]{11}$/'],
    'drivers_licence' => ['label' => "Driver's licence",      'pattern' => '/^[A-Z0-9]{8,15}$/'],
    'passport'        => ['label' => 'International passport', 'pattern' => '/^[A-Z]{1,2}[0-9]{7,8}$/'],
    'voters_card'     => ['label' => "Voter's card (VIN)",    'pattern' => '/^[A-Z0-9]{16,20}$/'],
];

// Creates the private documents folder, locked against direct web access.
// Returns the folder path (with trailing slash) or null on failure.
function avEnsureDir(): ?string
{
    if (!is_dir(AV_DIR) && !mkdir(AV_DIR, 0750, true) && !is_dir(AV_DIR)) {
        return null;
    }
    if (!file_exists(AV_DIR . '.htaccess')) {
        file_put_contents(AV_DIR . '.htaccess', "Require all denied\nDeny from all\n");
    }
    if (!file_exists(AV_DIR . 'index.html')) {
        file_put_contents(AV_DIR . 'index.html', '');
    }
    return AV_DIR;
}

// Best-effort push to one user; never throws.
function avNotifyUser(PDO $pdo, int $userId, string $title, string $body): void
{
    try {
        $q = $pdo->prepare('SELECT notification_token FROM users WHERE id = ?');
        $q->execute([$userId]);
        $token = (string) $q->fetchColumn();
        if ($token === '') return;

        $credentialsPath = __DIR__ . '/../include/firebase_credentials.json';
        if (!file_exists($credentialsPath)) return;
        require_once __DIR__ . '/../include/vendor/autoload.php';
        require_once __DIR__ . '/FcmNotificationSender.php';
        $account = json_decode(file_get_contents($credentialsPath), true);
        $sender = new FcmNotificationSender($account['project_id'], $credentialsPath);
        $sender->sendToDevice($token, $title, $body, ['type' => 'verification']);
    } catch (Throwable $e) {
        error_log('verification notify: ' . $e->getMessage());
    }
}
