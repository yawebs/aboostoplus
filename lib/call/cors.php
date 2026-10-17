<?php
// api/cors.php — must be require_once'd at the very top of every
// api/*.php endpoint, before any other output (even a stray blank
// line before "<?php" will break this, since HTTP headers can't be
// sent after output has started).

$allowedOrigins = [
    'http://localhost:8765',              // local Flutter web dev server
    'https://aboostoplus.com', // replace with your real deployed origin
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($origin, $allowedOrigins, true)) {
    header("Access-Control-Allow-Origin: $origin");
}

header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400'); // browser caches preflight for 24h

// The browser sends a separate OPTIONS "preflight" request before the
// real POST. It carries no useful body — answer it immediately so it
// never reaches your endpoint's actual logic below.
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}
