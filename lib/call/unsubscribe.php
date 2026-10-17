<?php
// unsubscribe.php: one-click unsubscribe from admin broadcast emails.
// GET shows a confirmation page; POST (including RFC 8058 one-click from Gmail/Yahoo) opts the user out.
declare(strict_types=1);

require __DIR__ . '/../include/db_con.php';
require_once __DIR__ . '/mail_lib.php';

$userId = (int) ($_GET['u'] ?? 0);
$sig    = (string) ($_GET['s'] ?? '');
$valid  = $userId > 0 && $sig !== '' && mailUnsubscribeValid($userId, $sig);
$done   = false;

if ($valid && $_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare('UPDATE users SET email_opt_out = 1 WHERE id = ?')->execute([$userId]);
        $done = true;
    } catch (Throwable $e) {
        error_log('unsubscribe.php: ' . $e->getMessage());
        $valid = false;
    }
    // Mail clients doing one-click unsubscribe only need a 2xx.
    if (($_POST['List-Unsubscribe'] ?? '') === 'One-Click') {
        http_response_code($done ? 200 : 400);
        exit;
    }
}

$self = htmlspecialchars("unsubscribe.php?u=$userId&s=" . rawurlencode($sig), ENT_QUOTES);
?><!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Unsubscribe · Aboostoplus</title>
<meta name="robots" content="noindex">
<style>
body{margin:0;min-height:100vh;display:grid;place-items:center;padding:24px;font-family:Segoe UI,Roboto,Arial,sans-serif;background:#f4f1f7;color:#1d1424}
.card{max-width:440px;background:#fff;border-radius:20px;padding:36px 32px;text-align:center;box-shadow:0 8px 30px rgba(63,34,79,.12)}
h1{font-family:Georgia,serif;color:#3F224F;font-size:26px;margin:0 0 10px}
p{color:#5a4f62;line-height:1.6;margin:0 0 22px}
button{background:#3F224F;color:#fff;border:0;border-radius:12px;padding:14px 26px;font-size:15px;font-weight:700;cursor:pointer}
a{color:#6A3D7A}
</style></head>
<body><div class="card">
<?php if (!$valid): ?>
  <h1>Link not valid</h1>
  <p>This unsubscribe link is invalid or has expired. Email <a href="mailto:support@aboostoplus.com">support@aboostoplus.com</a> and we’ll take you off our list.</p>
<?php elseif ($done): ?>
  <h1>You’re unsubscribed</h1>
  <p>You won’t receive announcement emails from Aboostoplus any more. You’ll still get important account emails, like password resets.</p>
  <a href="https://aboostoplus.com">Back to aboostoplus.com</a>
<?php else: ?>
  <h1>Unsubscribe?</h1>
  <p>Stop receiving announcement and update emails from Aboostoplus. Account emails such as password resets will still arrive.</p>
  <form method="post" action="<?= $self ?>"><button type="submit">Unsubscribe</button></form>
<?php endif; ?>
</div></body></html>
