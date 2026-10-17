<?php
// auth.php — session bootstrap + admin guard shared by every admin page.
declare(strict_types=1);

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function requireAdmin(): void
{
    if (empty($_SESSION['admin_id'])) {
        header('Location: login.php');
        exit;
    }
}

function currentAdminName(): string
{
    return $_SESSION['admin_name'] ?? 'Admin';
}

function csrfToken(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function verifyCsrf(?string $token): bool
{
    return is_string($token) && !empty($_SESSION['csrf']) && hash_equals($_SESSION['csrf'], $token);
}

function money($amount): string
{
    return '₦' . number_format((float) $amount, 0);
}

function timeAgo(?string $datetime): string
{
    if (!$datetime) return '—';
    $ts = strtotime($datetime);
    if (!$ts) return '—';
    $diff = time() - $ts;
    if ($diff < 60) return 'just now';
    if ($diff < 3600) return floor($diff / 60) . 'm ago';
    if ($diff < 86400) return floor($diff / 3600) . 'h ago';
    if ($diff < 2592000) return floor($diff / 86400) . 'd ago';
    return date('M j, Y', $ts);
}

function h($value): string
{
    return htmlspecialchars((string) ($value ?? ''), ENT_QUOTES, 'UTF-8');
}

function firstImage(?string $imagesJson): ?string
{
    if (!$imagesJson) return null;
    $decoded = json_decode($imagesJson, true);
    if (is_array($decoded) && count($decoded) > 0) {
        return $decoded[0];
    }
    return null;
}
