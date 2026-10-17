<?php
// Search-alert matching: called after a new listing is uploaded. Every
// active alert whose filters match the listing gets one push notification
// (at most one per alert per hour, so a burst of uploads can't spam).
//
// Never throws: a problem here must not break the upload itself.

function aboostoplusMatchesAlert(array $f, array $house): bool
{
    $num = fn($v) => (float) str_replace(',', '', (string) $v);

    if (!empty($f['categories']) && is_array($f['categories'])
        && !in_array($house['category'], $f['categories'], true)) {
        return false;
    }
    if (!empty($f['state']) && strcasecmp($f['state'], (string) $house['hLocation']) !== 0) {
        return false;
    }
    if (!empty($f['city']) && strcasecmp($f['city'], (string) $house['hCity']) !== 0) {
        return false;
    }
    if (!empty($f['community'])
        && stripos((string) $house['community'], trim($f['community'])) === false) {
        return false;
    }
    $amount = $num($house['amount']);
    if (isset($f['minPrice']) && $f['minPrice'] !== null && $amount < (float) $f['minPrice']) {
        return false;
    }
    if (isset($f['maxPrice']) && $f['maxPrice'] !== null && $amount > (float) $f['maxPrice']) {
        return false;
    }
    if (!empty($f['minRooms']) && (int) $house['rooms'] < (int) $f['minRooms']) {
        return false;
    }
    if (!empty($f['minBathrooms']) && (int) $house['bathrooms'] < (int) $f['minBathrooms']) {
        return false;
    }
    if (!empty($f['keyword'])) {
        $haystack = implode(' ', [
            $house['title'] ?? '', $house['category'] ?? '', $house['community'] ?? '',
            $house['hCity'] ?? '', $house['hLocation'] ?? '', $house['houseDesc'] ?? '',
        ]);
        if (stripos($haystack, trim($f['keyword'])) === false) {
            return false;
        }
    }
    return true;
}

function aboostoplusNotifySearchAlerts(PDO $pdo, int $propertyId): void
{
    try {
        $q = $pdo->prepare('SELECT * FROM houses WHERE id = ? LIMIT 1');
        $q->execute([$propertyId]);
        $house = $q->fetch(PDO::FETCH_ASSOC);
        if (!$house) return;

        $alerts = $pdo->query(
            "SELECT a.id, a.user_id, a.label, a.filters, u.notification_token
             FROM search_alerts a
             INNER JOIN users u ON u.uniqueId = a.user_id
             WHERE a.active = 1
               AND (a.last_notified_at IS NULL OR a.last_notified_at < (NOW() - INTERVAL 1 HOUR))"
        )->fetchAll(PDO::FETCH_ASSOC);

        $matches = [];
        foreach ($alerts as $a) {
            if ($a['user_id'] === $house['ownerId']) continue; // not your own listing
            if (empty($a['notification_token'])) continue;
            $filters = json_decode($a['filters'], true);
            if (is_array($filters) && aboostoplusMatchesAlert($filters, $house)) {
                $matches[] = $a;
            }
        }
        if (!$matches) return;

        require_once dirname(__DIR__) . '/include/vendor/autoload.php';
        require_once __DIR__ . '/FcmNotificationSender.php';
        $credentialsPath = dirname(__DIR__) . '/include/firebase_credentials.json';
        $projectId = json_decode(file_get_contents($credentialsPath), true)['project_id'];
        $sender = new FcmNotificationSender($projectId, $credentialsPath);

        $price = '₦' . number_format((float) str_replace(',', '', (string) $house['amount']));
        $where = trim(implode(', ', array_filter([$house['community'], $house['hCity']])));
        $title = '🏠 New match: ' . ($house['title'] ?: $house['category']);
        $summary = $price . ($where ? " · $where" : '');

        $mark = $pdo->prepare('UPDATE search_alerts SET last_notified_at = NOW() WHERE id = ?');
        foreach ($matches as $a) {
            try {
                $body = "$summary\nMatches your alert: {$a['label']}";
                $sender->sendToDevice($a['notification_token'], $title, $body, [
                    'type' => 'search_alert',
                    'alert_id' => (string) $a['id'],
                    'property_id' => (string) $propertyId,
                ]);
                $mark->execute([$a['id']]);
            } catch (Throwable $e) {
                error_log('search alert push failed for alert ' . $a['id'] . ': ' . $e->getMessage());
            }
        }
    } catch (Throwable $e) {
        // Most likely the search_alerts table doesn't exist yet.
        error_log('search alerts skipped: ' . $e->getMessage());
    }
}
