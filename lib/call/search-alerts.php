<?php
// Search alerts (saved searches).
// POST action=list    user_id                      -> {status, data: [alerts]}
// POST action=create  user_id, label, filters(JSON) -> {status, id}
// POST action=delete  user_id, id                  -> {status}
// POST action=toggle  user_id, id                  -> {status, active}
include '../include/db_con.php';
require_once __DIR__ . '/cors.php';

ini_set('display_errors', 0);
header('Content-type: application/json');

const MAX_ALERTS_PER_USER = 10;

$action = $_POST['action'] ?? '';
$userId = trim($_POST['user_id'] ?? '');

if ($userId === '') {
    echo json_encode(['status' => false, 'message' => 'Missing user']);
    exit;
}

try {
    if ($action === 'list') {
        $q = $pdo->prepare('SELECT id, label, filters, active, created_at, last_notified_at FROM search_alerts WHERE user_id = ? ORDER BY created_at DESC');
        $q->execute([$userId]);
        $rows = $q->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as &$r) {
            $r['filters'] = json_decode($r['filters'], true) ?: new stdClass();
            $r['active'] = (bool) $r['active'];
            $r['id'] = (int) $r['id'];
        }
        echo json_encode(['status' => true, 'data' => $rows]);
    } else if ($action === 'create') {
        $label = trim($_POST['label'] ?? '');
        $filters = json_decode($_POST['filters'] ?? '', true);
        if ($label === '' || !is_array($filters)) {
            echo json_encode(['status' => false, 'message' => 'Missing search details']);
            exit;
        }
        $count = $pdo->prepare('SELECT COUNT(*) FROM search_alerts WHERE user_id = ?');
        $count->execute([$userId]);
        if ((int) $count->fetchColumn() >= MAX_ALERTS_PER_USER) {
            echo json_encode(['status' => false, 'message' => 'You can have up to ' . MAX_ALERTS_PER_USER . ' alerts. Delete one to add another.']);
            exit;
        }
        $ins = $pdo->prepare('INSERT INTO search_alerts (user_id, label, filters) VALUES (?, ?, ?)');
        $ins->execute([$userId, mb_substr($label, 0, 160), json_encode($filters)]);
        echo json_encode(['status' => true, 'id' => (int) $pdo->lastInsertId()]);
    } else if ($action === 'delete') {
        $del = $pdo->prepare('DELETE FROM search_alerts WHERE id = ? AND user_id = ?');
        $del->execute([(int) ($_POST['id'] ?? 0), $userId]);
        echo json_encode(['status' => true]);
    } else if ($action === 'toggle') {
        $id = (int) ($_POST['id'] ?? 0);
        $upd = $pdo->prepare('UPDATE search_alerts SET active = 1 - active WHERE id = ? AND user_id = ?');
        $upd->execute([$id, $userId]);
        $q = $pdo->prepare('SELECT active FROM search_alerts WHERE id = ? AND user_id = ?');
        $q->execute([$id, $userId]);
        echo json_encode(['status' => true, 'active' => (bool) $q->fetchColumn()]);
    } else {
        echo json_encode(['status' => false, 'message' => 'Unknown action']);
    }
} catch (PDOException $e) {
    error_log('search-alerts: ' . $e->getMessage());
    echo json_encode(['status' => false, 'message' => 'Search alerts are unavailable right now']);
}
