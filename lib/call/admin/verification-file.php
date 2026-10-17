<?php
// Streams a private verification document to a signed-in admin.
//   verification-file.php?id=<agent_verifications.id>&f=front|back|selfie
declare(strict_types=1);

require __DIR__ . '/auth.php';
requireAdmin();
require __DIR__ . '/../../include/db_con.php';
require_once __DIR__ . '/../verification_lib.php';

$columns = ['front' => 'id_front', 'back' => 'id_back', 'selfie' => 'selfie'];
$col = $columns[$_GET['f'] ?? ''] ?? null;
if ($col === null) {
    http_response_code(400);
    exit;
}

$q = $pdo->prepare("SELECT $col FROM agent_verifications WHERE id = ?");
$q->execute([(int) ($_GET['id'] ?? 0)]);
$name = (string) $q->fetchColumn();

// Names are generated server-side, but never trust them as a path.
$path = AV_DIR . basename($name);
if ($name === '' || !is_file($path)) {
    http_response_code(404);
    exit;
}

$mime = (new finfo(FILEINFO_MIME_TYPE))->file($path);
header('Content-Type: ' . $mime);
header('Content-Length: ' . filesize($path));
header('Cache-Control: private, no-store');
header('X-Content-Type-Options: nosniff');
readfile($path);
