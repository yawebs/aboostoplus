<?php
// Transactional email through Resend (https://resend.com/docs/api-reference/emails/send-email).
// Config lives in ../include/mail_config.php (see mail_config.example.php).

function mailConfig(): ?array
{
    static $config = null;
    if ($config === null) {
        $path = __DIR__ . '/../include/mail_config.php';
        $config = file_exists($path) ? require $path : [];
    }
    return !empty($config['resend_api_key']) ? $config : null;
}

// Sends one email. Returns true when Resend accepted it; never throws.
function resendSend(string $to, string $subject, string $html, string $text): bool
{
    $config = mailConfig();
    if ($config === null) {
        error_log('resendSend: mail_config.php missing or has no resend_api_key');
        return false;
    }

    $payload = [
        'from'    => $config['from'] ?? 'Aboostoplus <no-reply@aboostoplus.com>',
        'to'      => [$to],
        'subject' => $subject,
        'html'    => $html,
        'text'    => $text,
    ];
    if (!empty($config['reply_to'])) {
        $payload['reply_to'] = $config['reply_to'];
    }

    $ch = curl_init('https://api.resend.com/emails');
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_HTTPHEADER     => [
            'Authorization: Bearer ' . $config['resend_api_key'],
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS     => json_encode($payload),
    ]);
    $body   = curl_exec($ch);
    $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error  = curl_error($ch);
    curl_close($ch);

    if ($status >= 200 && $status < 300) {
        return true;
    }
    error_log("resendSend: HTTP $status $error " . (is_string($body) ? $body : ''));
    return false;
}

// Sends many emails through Resend's batch endpoint (max 100 per request).
// $emails: list of ['to' => .., 'subject' => .., 'html' => .., 'text' => .., 'headers' => [..]?].
// Returns ['sent' => n, 'failed' => n]; never throws.
function resendSendBatch(array $emails): array
{
    $config = mailConfig();
    if ($config === null) {
        error_log('resendSendBatch: mail_config.php missing or has no resend_api_key');
        return ['sent' => 0, 'failed' => count($emails)];
    }
    $from = $config['from'] ?? 'Aboostoplus <no-reply@aboostoplus.com>';
    $sent = 0;
    $failed = 0;
    foreach (array_chunk($emails, 100) as $i => $chunk) {
        if ($i > 0) {
            usleep(600000); // stay under Resend's default rate limit (2 requests/second)
        }
        $payload = array_map(function ($e) use ($from, $config) {
            $m = ['from' => $from, 'to' => [$e['to']], 'subject' => $e['subject'], 'html' => $e['html'], 'text' => $e['text']];
            if (!empty($config['reply_to'])) $m['reply_to'] = $config['reply_to'];
            if (!empty($e['headers'])) $m['headers'] = $e['headers'];
            return $m;
        }, $chunk);

        $ch = curl_init('https://api.resend.com/emails/batch');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_HTTPHEADER     => ['Authorization: Bearer ' . $config['resend_api_key'], 'Content-Type: application/json'],
            CURLOPT_POSTFIELDS     => json_encode($payload),
        ]);
        $body   = curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($status >= 200 && $status < 300) {
            $sent += count($chunk);
        } else {
            $failed += count($chunk);
            error_log("resendSendBatch: HTTP $status " . (is_string($body) ? $body : ''));
        }
    }
    return ['sent' => $sent, 'failed' => $failed];
}

// Signed unsubscribe links, so nobody can unsubscribe someone else by guessing ids.
function mailUnsubscribeSecret(): string
{
    $config = mailConfig() ?? [];
    return (string) ($config['unsubscribe_secret'] ?? hash('sha256', 'aboostoplus-unsub|' . ($config['resend_api_key'] ?? '')));
}

function mailUnsubscribeUrl(int $userId): string
{
    $sig = substr(hash_hmac('sha256', (string) $userId, mailUnsubscribeSecret()), 0, 32);
    return "https://aboostoplus.com/api/unsubscribe.php?u=$userId&s=$sig";
}

function mailUnsubscribeValid(int $userId, string $sig): bool
{
    return hash_equals(substr(hash_hmac('sha256', (string) $userId, mailUnsubscribeSecret()), 0, 32), $sig);
}

// Admin-composed message. $message is plain text typed by the admin; {{first_name}} is personalised.
function mailAdminMessage(string $firstName, string $subject, string $message, string $ctaLabel = '', string $ctaUrl = '', string $unsubscribeUrl = ''): array
{
    $first   = $firstName !== '' ? $firstName : 'there';
    $message = str_replace(['{{first_name}}', '{{ first_name }}'], $first, $message);
    $paras   = preg_split('/\R{2,}/', trim($message));
    $body    = '';
    foreach ($paras as $para) {
        $body .= '<p style="margin:0 0 16px;font-size:15px;line-height:1.65;color:#4a4540">' . nl2br(htmlspecialchars($para, ENT_QUOTES)) . '</p>';
    }
    if ($ctaLabel !== '' && $ctaUrl !== '') {
        $u = htmlspecialchars($ctaUrl, ENT_QUOTES);
        $l = htmlspecialchars($ctaLabel, ENT_QUOTES);
        $body .= '<table role="presentation" cellpadding="0" cellspacing="0" style="margin:8px 0 4px"><tr><td style="border-radius:12px;background:#161616">'
               . "<a href=\"$u\" style=\"display:inline-block;padding:14px 26px;font-size:15px;font-weight:700;color:#ffffff;text-decoration:none;border-radius:12px\">$l</a>"
               . '</td></tr></table>';
    }
    $footer = $unsubscribeUrl !== ''
        ? 'You’re receiving this because you have a Aboostoplus account. <a href="' . htmlspecialchars($unsubscribeUrl, ENT_QUOTES) . '" style="color:#C45A06">Unsubscribe</a>'
        : '';
    $subjectP = str_replace(['{{first_name}}', '{{ first_name }}'], $first, $subject);
    $html = mailLayout(mb_substr(preg_replace('/\s+/', ' ', $message), 0, 120), $subjectP, $body, $footer);
    $text = $message . ($ctaLabel !== '' && $ctaUrl !== '' ? "\n\n$ctaLabel: $ctaUrl" : '')
          . ($unsubscribeUrl !== '' ? "\n\n—\nUnsubscribe: $unsubscribeUrl" : '') . "\n\nAboostoplus · aboostoplus.com";
    return [$subjectP, $html, $text];
}

// Branded wrapper shared by every transactional email. Table layout and inline
// styles because many email clients ignore <style> blocks.
function mailLayout(string $preheader, string $title, string $bodyHtml, string $footerHtml = ''): string
{
    $footerHtml = $footerHtml !== '' ? $footerHtml : 'You\'re receiving this because of activity on your Aboostoplus account.';
    $year = date('Y');
    $pre  = htmlspecialchars($preheader, ENT_QUOTES);
    $ttl  = htmlspecialchars($title, ENT_QUOTES);
    return <<<HTML
<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>$ttl</title></head>
<body style="margin:0;padding:0;background:#f4f1f7;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#161616">
<div style="display:none;max-height:0;overflow:hidden;opacity:0">$pre</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f1f7;padding:32px 12px">
<tr><td align="center">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 8px 30px rgba(22, 22, 22,.10)">
    <tr><td style="background:#161616;background:linear-gradient(135deg,#161616,#C45A06);padding:28px 32px">
      <div style="font-family:Georgia,'Times New Roman',serif;font-size:26px;font-weight:700;color:#ffffff;letter-spacing:.3px">Aboostoplus</div>
      <div style="font-size:13px;color:#FDB813;margin-top:4px;letter-spacing:.4px">Find a home. Know the area. Move in with ease.</div>
    </td></tr>
    <tr><td style="padding:32px">
      <h1 style="margin:0 0 12px;font-family:Georgia,'Times New Roman',serif;font-size:24px;line-height:1.25;color:#161616">$ttl</h1>
      $bodyHtml
    </td></tr>
    <tr><td style="padding:20px 32px;background:#faf8fc;border-top:1px solid #eee7f2;font-size:12px;line-height:1.6;color:#8a7f92">
      $footerHtml<br>
      &copy; $year Aboostoplus &middot; <a href="https://aboostoplus.com" style="color:#C45A06;text-decoration:none">aboostoplus.com</a>
    </td></tr>
  </table>
</td></tr>
</table>
</body></html>
HTML;
}

function mailPasswordResetCode(string $firstName, string $code, int $minutes): array
{
    $name   = htmlspecialchars($firstName !== '' ? $firstName : 'there', ENT_QUOTES);
    $spaced = implode(' ', str_split($code, 3));
    $html = mailLayout(
        "Your Aboostoplus reset code is $code",
        'Reset your password',
        <<<HTML
<p style="margin:0 0 20px;font-size:15px;line-height:1.6;color:#4a4540">Hi $name, use this code in the Aboostoplus app to reset your password.</p>
<div style="background:#faf6fc;border:1px solid #eadff0;border-radius:16px;padding:22px;text-align:center;margin:0 0 20px">
  <div style="font-size:12px;letter-spacing:2px;color:#8a7f92;margin-bottom:8px">YOUR CODE</div>
  <div style="font-family:Consolas,Menlo,monospace;font-size:36px;font-weight:700;letter-spacing:8px;color:#161616">$spaced</div>
  <div style="font-size:13px;color:#F7821B;font-weight:600;margin-top:10px">Expires in $minutes minutes</div>
</div>
<p style="margin:0;font-size:13px;line-height:1.6;color:#8a7f92">Didn't ask to reset your password? You can safely ignore this email. Your password stays the same, and never share this code with anyone, including Aboostoplus staff or agents.</p>
HTML
    );
    $text = "Hi $firstName,\n\nYour Aboostoplus password reset code is: $code\nIt expires in $minutes minutes.\n\n"
          . "Didn't ask to reset your password? Ignore this email. Never share this code with anyone.\n\nAboostoplus";
    return [$html, $text];
}

function mailPasswordChanged(string $firstName): array
{
    $name = htmlspecialchars($firstName !== '' ? $firstName : 'there', ENT_QUOTES);
    $when = date('j M Y, g:i A');
    $html = mailLayout(
        'Your Aboostoplus password was changed',
        'Your password was changed',
        <<<HTML
<p style="margin:0 0 16px;font-size:15px;line-height:1.6;color:#4a4540">Hi $name, the password for your Aboostoplus account was changed on <b>$when</b> (server time). For your security, you've been signed out on all devices.</p>
<div style="background:#fdf6e8;border:1px solid #f3dfb5;border-radius:14px;padding:16px 18px;font-size:14px;line-height:1.6;color:#6b4e12">
  <b>Wasn't you?</b> Reset your password again from the app straight away and contact
  <a href="mailto:support@aboostoplus.com" style="color:#C45A06">support@aboostoplus.com</a>.
</div>
HTML
    );
    $text = "Hi $firstName,\n\nThe password for your Aboostoplus account was changed on $when (server time). "
          . "You've been signed out on all devices.\n\nWasn't you? Reset your password again from the app and contact support@aboostoplus.com.\n\nAboostoplus";
    return [$html, $text];
}
