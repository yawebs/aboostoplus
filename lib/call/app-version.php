<?php
// App update prompt config, read by the app on launch (UpdateChecker).
// Android and iOS are configured SEPARATELY - their version/build numbers
// are independent (Play Console vs App Store Connect).
//
// WHEN YOU RELEASE AN UPDATE ON A PLATFORM:
//   1. Publish it in that store.
//   2. Once it's live, set that platform's latest_build + latest_version below
//      (the build number is Android's versionCode / the number after "+" in
//      pubspec.yaml, or iOS's "Build" number in App Store Connect).
//   3. Upload this file.
//
// latest_build: users on an older build see a dismissible "Update
//               available" sheet (again 3 days after tapping "Later").
// min_build:    users BELOW this build get a blocking "Update required"
//               screen. Only raise it for breaking changes. Keep it at 0
//               otherwise.
require_once __DIR__ . '/cors.php';
header('Content-Type: application/json');

$platforms = [
    'android' => [
        'latest_build'   => 24,
        'latest_version' => '14.14.18',
        'min_build'      => 0,
        'store_url'      => 'https://play.google.com/store/apps/details?id=com.aboostoplus.app',
    ],
    'ios' => [
        // Set these to the build/version that is LIVE on the App Store
        // (App Store Connect -> your app -> the live version -> Build).
        'latest_build'   => 15,
        'latest_version' => '1.0.4',
        'min_build'      => 0,
        'store_url'      => 'https://apps.apple.com/app/idYOUR_APP_STORE_ID',
    ],
];

// Shared copy for the popup (a platform can override with its own
// 'title' / 'notes' keys above if needed).
$title = 'A fresh update is here';
$notes = [
    'Redesigned chats, inspections and home feed',
    'AI insights about the area around every listing',
    'Faster loading and bug fixes',
];

echo json_encode([
    'title'     => $title,
    'notes'     => $notes,
    'platforms' => $platforms,

    // Legacy fields for app versions released before per-platform support.
    // Those builds read these top-level keys on BOTH platforms (they can't
    // tell iOS from Android here), so they keep the old single-number
    // behaviour until users update. New builds read `platforms` instead.
    'latest_build'   => $platforms['android']['latest_build'],
    'latest_version' => $platforms['android']['latest_version'],
    'min_build'      => $platforms['android']['min_build'],
    'android_url'    => $platforms['android']['store_url'],
    'ios_url'        => $platforms['ios']['store_url'],
]);
