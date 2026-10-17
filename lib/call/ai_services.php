<?php

// Manual test for the area insights AI call (the app uses area-insights.php).
include '../include/db_con.php';
include '../func/helper.php';

$aiService = new Helper();
$insight = $aiService->getAreaInsights("Ikeja GRA", "Ikeja", "Lagos State", "3 Bedroom Flat");

// Return this to your Flutter app as JSON
echo json_encode(['insight' => $insight]);
