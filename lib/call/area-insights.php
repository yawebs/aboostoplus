<?php
// AI neighbourhood summary for a listing's area (house details screen).
// POST: community, city, state, category
include '../include/db_con.php';
include '../func/helper.php';
require_once __DIR__ . '/cors.php';

ini_set('display_errors', 0);
// A first-time area can take ~15-60s (AI call + one retry if Gemini is
// overloaded); PHP's default 30s limit would kill it mid-request.
set_time_limit(90);
header('Content-type: application/json');

$community = trim($_POST['community'] ?? '');
$city = trim($_POST['city'] ?? '');
$state = trim($_POST['state'] ?? '');
$category = trim($_POST['category'] ?? 'property');

if ($community === '' && $city === '') {
    echo json_encode(['status' => false, 'message' => 'Missing area']);
    exit;
}

$helper = new Helper;
$insights = $helper->getAreaInsights($community, $city, $state, $category);

if ($insights === null) {
    echo json_encode(['status' => false, 'message' => 'Area insights are unavailable right now']);
} else {
    echo json_encode(['status' => true, 'data' => $insights]);
}
