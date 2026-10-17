<?php
// Saved homes ("hearts").
// POST action=ids     user_id                -> {status, data: [property ids]}
// POST action=list    user_id                -> {status, data: [house rows]}
// POST action=toggle  user_id, property_id   -> {status, saved: bool}
include '../include/db_con.php';
require_once __DIR__ . '/cors.php';

ini_set('display_errors', 0);
header('Content-type: application/json');

$action = $_POST['action'] ?? '';
$userId = trim($_POST['user_id'] ?? '');

if ($userId === '') {
    echo json_encode(['status' => false, 'message' => 'Missing user']);
    exit;
}

try {
    if ($action === 'ids') {
        $q = $pdo->prepare('SELECT property_id FROM saved_properties WHERE user_id = ? ORDER BY created_at DESC');
        $q->execute([$userId]);
        echo json_encode(['status' => true, 'data' => array_map('intval', $q->fetchAll(PDO::FETCH_COLUMN))]);
    } else if ($action === 'list') {
        // Only listings that still exist and are active.
        $q = $pdo->prepare(
            "SELECT h.* FROM saved_properties s
             INNER JOIN houses h ON h.id = s.property_id
             WHERE s.user_id = ? AND h.status = 'active'
             ORDER BY s.created_at DESC
             LIMIT 200"
        );
        $q->execute([$userId]);
        echo json_encode(['status' => true, 'data' => $q->fetchAll(PDO::FETCH_ASSOC)]);
    } else if ($action === 'toggle') {
        $propertyId = (int) ($_POST['property_id'] ?? 0);
        if ($propertyId <= 0) {
            echo json_encode(['status' => false, 'message' => 'Missing property']);
            exit;
        }
        $del = $pdo->prepare('DELETE FROM saved_properties WHERE user_id = ? AND property_id = ?');
        $del->execute([$userId, $propertyId]);
        if ($del->rowCount() > 0) {
            echo json_encode(['status' => true, 'saved' => false]);
        } else {
            $ins = $pdo->prepare('INSERT IGNORE INTO saved_properties (user_id, property_id) VALUES (?, ?)');
            $ins->execute([$userId, $propertyId]);
            echo json_encode(['status' => true, 'saved' => true]);
        }
    } else {
        echo json_encode(['status' => false, 'message' => 'Unknown action']);
    }
} catch (PDOException $e) {
    error_log('saved-properties: ' . $e->getMessage());
    echo json_encode(['status' => false, 'message' => 'Saved homes are unavailable right now']);
}
