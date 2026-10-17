<?php
// index.php — main admin dashboard: overview, users, inspections, reports, properties.
declare(strict_types=1);

require __DIR__ . '/auth.php';
requireAdmin();
require __DIR__ . '/../../include/db_con.php';

$csrf = csrfToken();

/* ---------- Overview counts ---------- */
$totalUsers      = (int) $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
$totalAgents     = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE userType = 'Agent'")->fetchColumn();
$totalProperties = (int) $pdo->query("SELECT COUNT(*) FROM houses")->fetchColumn();
$totalProducts   = (int) $pdo->query("SELECT COUNT(*) FROM market_place")->fetchColumn();
$pendingInspectionsCount = (int) $pdo->query(
    "SELECT COUNT(*) FROM deals_tbl WHERE dealStatus IS NULL OR dealStatus NOT IN ('Completed','Cancelled')"
)->fetchColumn();
$pendingReportsCount = (int) $pdo->query(
    "SELECT COUNT(*) FROM content_reports WHERE status IS NULL OR status = 'pending'"
)->fetchColumn();

/* ---------- Users ---------- */
$users = $pdo->query(
    "SELECT id, uniqueId, firstname, lastname, email, phone, userType, profileImage, account_status, createdAt
     FROM users ORDER BY createdAt DESC LIMIT 500"
)->fetchAll();

/* ---------- Pending inspections (deals_tbl) ---------- */
$inspections = $pdo->query(
    "SELECT d.*, a.firstname AS agent_first, a.lastname AS agent_last
     FROM deals_tbl d
     LEFT JOIN users a ON a.uniqueId = d.agent_id
     WHERE d.dealStatus IS NULL OR d.dealStatus NOT IN ('Completed','Cancelled')
     ORDER BY d.dateCreated DESC LIMIT 500"
)->fetchAll();

/* ---------- Pending reports ---------- */
$reports = $pdo->query(
    "SELECT r.*, u.firstname AS reporter_first, u.lastname AS reporter_last
     FROM content_reports r
     LEFT JOIN users u ON u.id = r.reporter_id
     WHERE r.status IS NULL OR r.status = 'pending'
     ORDER BY r.created_at DESC LIMIT 500"
)->fetchAll();

$reasonLabels = [
    'misleading' => 'Misleading listing',
    'fake'       => 'Fake / scam',
    'agent'      => 'Agent misconduct',
    'scam'       => 'Scam',
    'content'    => 'Inappropriate content',
    'other'      => 'Other',
];

/* Resolve each report's target label without a fragile cross-type JOIN */
foreach ($reports as &$r) {
    if ($r['target_type'] === 'property') {
        $t = $pdo->prepare('SELECT title FROM houses WHERE id = ?');
        $t->execute([$r['target_id']]);
        $r['target_label'] = $t->fetchColumn() ?: ('Property #' . $r['target_id']);
    } else {
        $t = $pdo->prepare("SELECT CONCAT(firstname, ' ', lastname) FROM users WHERE id = ?");
        $t->execute([$r['target_id']]);
        $r['target_label'] = $t->fetchColumn() ?: ('User #' . $r['target_id']);
    }
}
unset($r);

/* ---------- Properties ---------- */
$properties = $pdo->query(
    "SELECT h.*, u.firstname AS owner_first, u.lastname AS owner_last, u.email AS owner_email
     FROM houses h
     LEFT JOIN users u ON u.uniqueId = h.ownerId
     ORDER BY h.dateCreated DESC LIMIT 500"
)->fetchAll();

/* ---------- Marketplace products ---------- */
$products = $pdo->query(
    "SELECT m.*, u.firstname AS owner_first, u.lastname AS owner_last, u.email AS owner_email
     FROM market_place m
     LEFT JOIN users u ON u.uniqueId = m.ownerId
     ORDER BY m.createdAt DESC LIMIT 500"
)->fetchAll();

/* ---------- Users reachable by push notification ---------- */
$notifiableUsers = $pdo->query(
    "SELECT uniqueId, firstname, lastname, email, userType
     FROM users
     WHERE notification_token IS NOT NULL AND notification_token <> '' AND account_status = 'active'
     ORDER BY firstname"
)->fetchAll();
$notifiableAgents = array_values(array_filter($notifiableUsers, fn($u) => $u['userType'] === 'Agent'));
$notifiableRegular = array_values(array_filter($notifiableUsers, fn($u) => $u['userType'] === 'User'));

/* ---------- Users reachable by email ---------- */
// Wrapped so the dashboard still loads before admin_emails.sql is run.
$emailsReady = true;
$emailableUsers = [];
$emailLog = [];
try {
    $emailableUsers = $pdo->query(
        "SELECT id, firstname, lastname, email, userType, email_opt_out
         FROM users
         WHERE email <> '' AND email NOT LIKE '%@deleted.aboostoplus.invalid' AND account_status = 'active' AND userType <> 'Admin'
         ORDER BY firstname"
    )->fetchAll();
    $emailLog = $pdo->query('SELECT * FROM admin_email_log ORDER BY created_at DESC LIMIT 15')->fetchAll();
} catch (Throwable $e) {
    $emailsReady = false;
}
$subscribed = array_values(array_filter($emailableUsers, fn($u) => !(int) $u['email_opt_out']));
$emailAgents = count(array_filter($subscribed, fn($u) => $u['userType'] === 'Agent'));
$emailRegular = count(array_filter($subscribed, fn($u) => $u['userType'] === 'User'));
$emailOptedOut = count($emailableUsers) - count($subscribed);

/* ---------- Agent verifications ---------- */
// Wrapped so the dashboard still loads before agent_verification.sql is run.
require_once __DIR__ . '/../verification_lib.php';
$pendingVerifications = [];
$verifiedAgents = [];
$verificationsReady = true;
try {
    $pendingVerifications = $pdo->query(
        "SELECT v.*, u.firstname, u.lastname, u.email, u.phone, u.profileImage, u.userType, u.createdAt AS joined,
                (SELECT COUNT(*) FROM agent_verifications p WHERE p.user_id = v.user_id AND p.status = 'rejected') AS past_rejections
         FROM agent_verifications v
         LEFT JOIN users u ON u.id = v.user_id
         WHERE v.status = 'pending'
         ORDER BY v.created_at ASC LIMIT 200"
    )->fetchAll();
    $verifiedAgents = $pdo->query(
        "SELECT id, firstname, lastname, email, userType, profileImage, verified_at
         FROM users WHERE is_verified = 1 ORDER BY verified_at DESC LIMIT 500"
    )->fetchAll();
} catch (Throwable $e) {
    $verificationsReady = false;
}
$pendingVerificationsCount = count($pendingVerifications);

function statusBadge(?string $status): string
{
    $status = $status ?: 'active';
    $map = [
        'active'       => 'success',
        'suspended'    => 'danger',
        'removed'      => 'dark',
        'under_review' => 'warning',
        'pending'      => 'secondary',
    ];
    $variant = $map[$status] ?? 'secondary';
    return '<span class="badge rounded-pill text-bg-' . $variant . '">' . h(ucwords(str_replace('_', ' ', $status))) . '</span>';
}

function dealBadge(?string $status): string
{
    $status = $status ?: 'Pending';
    $map = ['Completed' => 'success', 'Cancelled' => 'danger', 'Pending' => 'secondary'];
    $variant = $map[$status] ?? 'secondary';
    return '<span class="badge rounded-pill text-bg-' . $variant . '">' . h($status) . '</span>';
}

// Inline SVG placeholders — no external network call, so a broken/slow
// placeholder CDN (e.g. via.placeholder.com) can never hang page load.
// Quotes inside the SVG are percent-encoded (%22) rather than literal, so this
// string is safe to drop into a double-quoted HTML attribute AND a
// single-quoted inline JS string (the onerror handler) without breaking either.
const AVATAR_PLACEHOLDER = 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 40 40%22%3E%3Crect width=%2240%22 height=%2240%22 rx=%2220%22 fill=%22%23e5e3f5%22/%3E%3Ccircle cx=%2220%22 cy=%2216%22 r=%227%22 fill=%22%23b3b1c9%22/%3E%3Cpath d=%22M6 34c0-8 6-13 14-13s14 5 14 13%22 fill=%22%23b3b1c9%22/%3E%3C/svg%3E';
const THUMB_PLACEHOLDER  = 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 56 44%22%3E%3Crect width=%2256%22 height=%2244%22 rx=%228%22 fill=%22%23eeeeee%22/%3E%3Cpath d=%22M14 32l9-10 7 7 6-7 9 10%22 stroke=%22%23c7c5db%22 stroke-width=%222%22 fill=%22none%22/%3E%3Ccircle cx=%2219%22 cy=%2216%22 r=%223%22 fill=%22%23c7c5db%22/%3E%3C/svg%3E';

$activeTab = $_GET['tab'] ?? 'overview';
$flashMsg  = $_GET['msg'] ?? '';
$flashType = $_GET['type'] ?? 'success';
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin Dashboard · Aboostoplus</title>
<link rel="icon" type="image/png" href="assets/icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
<style>
  :root{
    --brand:#4f46e5;
    --brand-dark:#3730a3;
    --bg:#f4f5fb;
    --sidebar:#161327;
  }
  *{font-family:'Inter',system-ui,sans-serif;}
  body{background:var(--bg);}

  /* ---------- Sidebar ---------- */
  .sidebar{
    width:250px;position:fixed;inset:0 auto 0 0;
    background:linear-gradient(180deg,var(--sidebar),#0d0b1a);
    color:#cfcbe6;display:flex;flex-direction:column;z-index:1030;
  }
  .sidebar .brand{
    display:flex;align-items:center;gap:10px;padding:22px 20px;
    color:#fff;font-weight:800;font-size:1.05rem;border-bottom:1px solid rgba(255,255,255,.06);
  }
  .sidebar .brand .icon{
    width:36px;height:36px;
    display:flex;align-items:center;justify-content:center;
  }
  .sidebar .brand .icon img{width:100%;height:100%;object-fit:contain;}
  .sidebar .nav-link{
    color:#b9b4d6;padding:11px 20px;border-radius:10px;margin:2px 12px;
    font-weight:500;font-size:.92rem;display:flex;align-items:center;gap:10px;
  }
  .sidebar .nav-link i{font-size:1.05rem;width:20px;text-align:center;}
  .sidebar .nav-link:hover{background:rgba(255,255,255,.06);color:#fff;}
  .sidebar .nav-link.active{background:linear-gradient(135deg,var(--brand),#6d28d9);color:#fff;box-shadow:0 6px 16px -4px rgba(79,70,229,.6);}
  .sidebar .nav-pills{margin-top:14px;flex:1;}
  .sidebar .badge-count{margin-left:auto;background:rgba(255,255,255,.12);font-weight:600;}
  .sidebar .nav-link.active .badge-count{background:rgba(255,255,255,.25);}
  .sidebar-footer{padding:16px 20px;border-top:1px solid rgba(255,255,255,.06);}
  .sidebar-footer .admin-name{color:#fff;font-weight:600;font-size:.88rem;}

  .main{margin-left:250px;padding:26px 30px 60px;}
  .topbar{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px;}
  .topbar h3{font-weight:800;margin:0;color:#1e1b3a;}
  .topbar p{margin:0;color:#8b8aa3;font-size:.9rem;}

  /* ---------- Stat cards ---------- */
  .stat-card{
    background:#fff;border:none;border-radius:16px;padding:20px;
    box-shadow:0 6px 18px -8px rgba(30,27,58,.12);border-left:4px solid var(--brand);
    display:flex;align-items:center;gap:14px;
  }
  .stat-card .stat-icon{
    width:48px;height:48px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:20px;
  }
  .stat-card h4{margin:0;font-weight:800;color:#1e1b3a;}
  .stat-card span{color:#8b8aa3;font-size:.82rem;font-weight:500;}

  /* ---------- Content cards ---------- */
  .panel{background:#fff;border-radius:16px;box-shadow:0 6px 18px -8px rgba(30,27,58,.1);border:none;}
  .panel .panel-head{padding:20px 22px;border-bottom:1px solid #f0eef8;display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap;}
  .panel .panel-head h5{margin:0;font-weight:700;color:#1e1b3a;}
  .table{margin:0;}
  .table thead th{
    background:#faf9ff;color:#8b8aa3;font-size:.72rem;text-transform:uppercase;letter-spacing:.04em;
    font-weight:700;border-bottom:none;padding:12px 22px;white-space:nowrap;
  }
  .table tbody td{padding:14px 22px;vertical-align:middle;font-size:.88rem;color:#3a3856;border-bottom:1px solid #f4f3fa;}
  .table tbody tr:last-child td{border-bottom:none;}
  .avatar{width:38px;height:38px;border-radius:50%;object-fit:cover;background:#eee;}
  .thumb{width:56px;height:44px;border-radius:8px;object-fit:cover;background:#eee;}
  .search-box{position:relative;width:260px;}
  .search-box i{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:#b3b1c9;}
  .search-box input{padding-left:34px;border-radius:10px;background:#faf9ff;border:1px solid #ece9f8;}
  .btn-icon{width:33px;height:33px;padding:0;display:inline-flex;align-items:center;justify-content:center;border-radius:9px;}
  .btn-brand{background:linear-gradient(135deg,var(--brand),var(--brand-dark));border:none;color:#fff;font-weight:600;}
  .btn-brand:hover{color:#fff;filter:brightness(1.08);}
  .tab-pane{display:none;}
  .tab-pane.show{display:block;}
  .empty-row td{text-align:center;color:#b3b1c9;padding:40px 22px;}
  .verify-card{padding:20px 22px;border-bottom:1px solid #f0eef8;}
  .verify-card:last-child{border-bottom:none;}
  .verify-facts{display:grid;grid-template-columns:110px 1fr;gap:6px 12px;margin:0;font-size:.86rem;}
  .verify-facts dt{color:#8b8aa3;font-weight:500;}
  .verify-facts dd{margin:0;color:#1e1b3a;font-weight:600;word-break:break-word;}
  .verify-doc{display:block;width:160px;text-decoration:none;}
  .verify-doc img{width:160px;height:110px;object-fit:cover;border-radius:12px;background:#eee;border:1px solid #ece9f8;transition:transform .15s;}
  .verify-doc:hover img{transform:scale(1.03);}
  .verify-doc span{display:block;font-size:.75rem;color:#8b8aa3;margin-top:4px;text-align:center;}
  @media (max-width:900px){
    .sidebar{width:78px;}
    .sidebar .brand span.brand-text, .sidebar .nav-link span.link-text, .sidebar-footer .admin-name, .sidebar-footer small{display:none;}
    .sidebar .nav-link{justify-content:center;margin:2px 10px;}
    .sidebar .badge-count{display:none;}
    .main{margin-left:78px;}
  }
</style>
</head>
<body>

<aside class="sidebar">
  <div class="brand"><div class="icon"><img src="assets/icon.png" alt="Aboostoplus"></div><span class="brand-text">Aboostoplus Admin</span></div>
  <div class="nav flex-column nav-pills" id="adminTabs">
    <a class="nav-link" data-tab="overview" href="#"><i class="bi bi-grid-1x2-fill"></i><span class="link-text">Overview</span></a>
    <a class="nav-link" data-tab="users" href="#"><i class="bi bi-people-fill"></i><span class="link-text">Users</span><span class="badge rounded-pill badge-count"><?= $totalUsers ?></span></a>
    <a class="nav-link" data-tab="verifications" href="#"><i class="bi bi-patch-check-fill"></i><span class="link-text">Verifications</span><span class="badge rounded-pill badge-count"><?= $pendingVerificationsCount ?></span></a>
    <a class="nav-link" data-tab="inspections" href="#"><i class="bi bi-calendar-check-fill"></i><span class="link-text">Inspections</span><span class="badge rounded-pill badge-count"><?= $pendingInspectionsCount ?></span></a>
    <a class="nav-link" data-tab="reports" href="#"><i class="bi bi-flag-fill"></i><span class="link-text">Reports</span><span class="badge rounded-pill badge-count"><?= $pendingReportsCount ?></span></a>
    <a class="nav-link" data-tab="properties" href="#"><i class="bi bi-house-door-fill"></i><span class="link-text">Properties</span><span class="badge rounded-pill badge-count"><?= $totalProperties ?></span></a>
    <a class="nav-link" data-tab="products" href="#"><i class="bi bi-bag-fill"></i><span class="link-text">Products</span><span class="badge rounded-pill badge-count"><?= $totalProducts ?></span></a>
    <a class="nav-link" data-tab="notifications" href="#"><i class="bi bi-bell-fill"></i><span class="link-text">Notifications</span></a>
    <a class="nav-link" data-tab="emails" href="#"><i class="bi bi-envelope-paper-fill"></i><span class="link-text">Emails</span></a>
  </div>
  <div class="sidebar-footer d-flex align-items-center gap-2">
    <div class="icon" style="width:34px;height:34px;border-radius:9px;background:rgba(255,255,255,.08);display:flex;align-items:center;justify-content:center;">
      <i class="bi bi-person-fill text-white"></i>
    </div>
    <div class="flex-grow-1">
      <div class="admin-name"><?= h(currentAdminName()) ?></div>
      <small class="text-white-50" style="font-size:.72rem;">Administrator</small>
    </div>
    <a href="logout.php" class="btn-icon btn btn-sm" style="background:rgba(255,255,255,.08);color:#fff;" title="Log out"><i class="bi bi-box-arrow-right"></i></a>
  </div>
</aside>

<main class="main">

  <?php if ($flashMsg): ?>
  <div class="alert alert-<?= h($flashType) ?> alert-dismissible fade show" role="alert">
    <?= h($flashMsg) ?>
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  </div>
  <?php endif; ?>

  <!-- ================= OVERVIEW ================= -->
  <section class="tab-pane" data-pane="overview">
    <div class="topbar">
      <div><h3>Dashboard Overview</h3><p>Welcome back, <?= h(currentAdminName()) ?> — here's what's happening on Aboostoplus.</p></div>
    </div>
    <div class="row g-3 mb-4">
      <div class="col-sm-6 col-lg-3">
        <div class="stat-card"><div class="stat-icon" style="background:#eef2ff;color:#4f46e5;"><i class="bi bi-people-fill"></i></div>
          <div><h4><?= $totalUsers ?></h4><span>Total Users</span></div></div>
      </div>
      <div class="col-sm-6 col-lg-3">
        <div class="stat-card" style="border-color:#0ea5e9;"><div class="stat-icon" style="background:#e0f2fe;color:#0ea5e9;"><i class="bi bi-person-badge-fill"></i></div>
          <div><h4><?= $totalAgents ?></h4><span>Agents</span></div></div>
      </div>
      <div class="col-sm-6 col-lg-3">
        <div class="stat-card" style="border-color:#f59e0b;"><div class="stat-icon" style="background:#fef3c7;color:#f59e0b;"><i class="bi bi-calendar-check-fill"></i></div>
          <div><h4><?= $pendingInspectionsCount ?></h4><span>Pending Inspections</span></div></div>
      </div>
      <div class="col-sm-6 col-lg-3">
        <div class="stat-card" style="border-color:#ef4444;"><div class="stat-icon" style="background:#fee2e2;color:#ef4444;"><i class="bi bi-flag-fill"></i></div>
          <div><h4><?= $pendingReportsCount ?></h4><span>Pending Reports</span></div></div>
      </div>
    </div>
    <div class="row g-3">
      <div class="col-lg-4">
        <div class="panel">
          <div class="panel-head"><h5><i class="bi bi-house-door-fill me-2 text-primary"></i>Total Properties</h5></div>
          <div class="p-4"><h2 class="fw-bold mb-0"><?= $totalProperties ?></h2><span class="text-muted small">listings uploaded across the platform</span></div>
        </div>
      </div>
      <div class="col-lg-4">
        <div class="panel">
          <div class="panel-head"><h5><i class="bi bi-bag-fill me-2 text-primary"></i>Total Products</h5></div>
          <div class="p-4"><h2 class="fw-bold mb-0"><?= $totalProducts ?></h2><span class="text-muted small">marketplace items uploaded by users</span></div>
        </div>
      </div>
      <div class="col-lg-4">
        <div class="panel">
          <div class="panel-head"><h5><i class="bi bi-lightning-charge-fill me-2 text-warning"></i>Needs Attention</h5></div>
          <div class="p-4 d-flex flex-column gap-2">
            <a href="#" class="jump-tab d-flex justify-content-between text-decoration-none text-dark" data-tab="verifications"><span><i class="bi bi-patch-check me-2 text-primary"></i>Agents awaiting verification</span><strong><?= $pendingVerificationsCount ?></strong></a>
            <a href="#" class="jump-tab d-flex justify-content-between text-decoration-none text-dark" data-tab="reports"><span><i class="bi bi-flag me-2 text-danger"></i>Unresolved reports</span><strong><?= $pendingReportsCount ?></strong></a>
            <a href="#" class="jump-tab d-flex justify-content-between text-decoration-none text-dark" data-tab="inspections"><span><i class="bi bi-calendar-event me-2 text-warning"></i>Inspections awaiting outcome</span><strong><?= $pendingInspectionsCount ?></strong></a>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- ================= USERS ================= -->
  <section class="tab-pane" data-pane="users">
    <div class="topbar">
      <div><h3>Users</h3><p>Everyone registered on Aboostoplus — activate, suspend, or remove accounts.</p></div>
    </div>
    <div class="panel">
      <div class="panel-head">
        <h5><i class="bi bi-people-fill me-2 text-primary"></i>All Users <span class="text-muted fw-normal">(<?= count($users) ?>)</span></h5>
        <div class="search-box"><i class="bi bi-search"></i><input type="text" class="form-control form-control-sm" data-search-target="users-table" placeholder="Search users..."></div>
      </div>
      <div class="table-responsive">
        <table class="table" id="users-table">
          <thead><tr><th>User</th><th>Contact</th><th>Type</th><th>Status</th><th>Joined</th><th class="text-end">Actions</th></tr></thead>
          <tbody>
          <?php if (!$users): ?>
            <tr class="empty-row"><td colspan="6">No users yet.</td></tr>
          <?php endif; ?>
          <?php foreach ($users as $u): ?>
            <tr>
              <td>
                <div class="d-flex align-items-center gap-2">
                  <img class="avatar" src="<?= h($u['profileImage'] ?: AVATAR_PLACEHOLDER) ?>" onerror="this.onerror=null;this.src='<?= AVATAR_PLACEHOLDER ?>'">
                  <div><div class="fw-semibold"><?= h(trim($u['firstname'] . ' ' . $u['lastname'])) ?></div><div class="text-muted" style="font-size:.78rem;">#<?= h($u['id']) ?></div></div>
                </div>
              </td>
              <td><div><?= h($u['email']) ?></div><div class="text-muted" style="font-size:.78rem;"><?= h($u['phone']) ?></div></td>
              <td><span class="badge rounded-pill text-bg-light border"><?= h($u['userType']) ?></span></td>
              <td><?= statusBadge($u['account_status']) ?></td>
              <td><?= h(timeAgo($u['createdAt'])) ?></td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <?php if (($u['account_status'] ?? 'active') === 'active'): ?>
                    <button class="btn btn-icon btn-outline-warning" data-bs-toggle="modal" data-bs-target="#actionModal"
                      data-action="suspend_user" data-id="<?= h($u['id']) ?>" data-tab="users" data-variant="warning" data-icon="bi-slash-circle"
                      data-title="Suspend this user?" data-text="<?= h(trim($u['firstname'].' '.$u['lastname'])) ?> won't be able to use their account, and their live listings will be hidden." title="Suspend">
                      <i class="bi bi-slash-circle"></i></button>
                  <?php else: ?>
                    <button class="btn btn-icon btn-outline-success" data-bs-toggle="modal" data-bs-target="#actionModal"
                      data-action="activate_user" data-id="<?= h($u['id']) ?>" data-tab="users" data-variant="success" data-icon="bi-check-circle"
                      data-title="Re-activate this user?" data-text="<?= h(trim($u['firstname'].' '.$u['lastname'])) ?> will regain full access to their account." title="Activate">
                      <i class="bi bi-check-circle"></i></button>
                  <?php endif; ?>
                  <button class="btn btn-icon btn-outline-danger" data-bs-toggle="modal" data-bs-target="#actionModal"
                    data-action="delete_user" data-id="<?= h($u['id']) ?>" data-tab="users" data-variant="danger" data-icon="bi-trash3"
                    data-title="Delete this user permanently?" data-text="This cannot be undone. <?= h(trim($u['firstname'].' '.$u['lastname'])) ?>'s account will be permanently removed." title="Delete">
                    <i class="bi bi-trash3"></i></button>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- ================= VERIFICATIONS ================= -->
  <section class="tab-pane" data-pane="verifications">
    <div class="topbar">
      <div><h3>Agent verification</h3><p>Check each agent's ID against their selfie and details. Only approved agents get the verified badge.</p></div>
    </div>

    <?php if (!$verificationsReady): ?>
      <div class="alert alert-warning">Run <code>lib/call/sql/agent_verification.sql</code> on the database to enable verifications.</div>
    <?php endif; ?>

    <div class="panel mb-4">
      <div class="panel-head">
        <h5><i class="bi bi-hourglass-split me-2 text-warning"></i>Awaiting review <span class="text-muted fw-normal">(<?= $pendingVerificationsCount ?>)</span></h5>
        <small class="text-muted">Oldest first</small>
      </div>
      <?php if (!$pendingVerifications): ?>
        <div class="text-center text-muted py-5"><i class="bi bi-patch-check fs-2 d-block mb-2"></i>No requests waiting. You're all caught up.</div>
      <?php endif; ?>
      <?php foreach ($pendingVerifications as $v):
        $name = trim(($v['firstname'] ?? '') . ' ' . ($v['lastname'] ?? ''));
        $idLabel = AV_ID_TYPES[$v['id_type']]['label'] ?? $v['id_type'];
        $docs = ['front' => 'ID front', 'back' => 'ID back', 'selfie' => 'Selfie'];
      ?>
        <div class="verify-card">
          <div class="d-flex align-items-start justify-content-between gap-3 flex-wrap">
            <div class="d-flex align-items-center gap-3">
              <img class="avatar" style="width:48px;height:48px;" src="<?= h($v['profileImage'] ?: AVATAR_PLACEHOLDER) ?>" onerror="this.onerror=null;this.src='<?= AVATAR_PLACEHOLDER ?>'">
              <div>
                <div class="fw-bold" style="color:#1e1b3a;"><?= h($name ?: 'Unknown user') ?> <span class="badge rounded-pill text-bg-light border ms-1"><?= h($v['userType']) ?></span></div>
                <div class="text-muted" style="font-size:.8rem;"><?= h($v['email']) ?> · <?= h($v['phone']) ?> · joined <?= h(timeAgo($v['joined'])) ?></div>
              </div>
            </div>
            <div class="text-end">
              <div class="text-muted" style="font-size:.78rem;">Submitted <?= h(timeAgo($v['created_at'])) ?></div>
              <?php if ((int) $v['past_rejections'] > 0): ?>
                <span class="badge text-bg-warning mt-1"><?= (int) $v['past_rejections'] ?> earlier rejection<?= (int) $v['past_rejections'] > 1 ? 's' : '' ?></span>
              <?php endif; ?>
            </div>
          </div>

          <div class="row g-3 mt-1">
            <div class="col-lg-5">
              <dl class="verify-facts">
                <dt>Legal name</dt><dd><?= h($v['legal_name']) ?></dd>
                <dt>Business</dt><dd><?= h($v['business_name'] ?: '—') ?></dd>
                <dt>CAC number</dt><dd><?= h($v['cac_number'] ?: '—') ?></dd>
                <dt>Office</dt><dd><?= h($v['office_address']) ?>, <?= h($v['state']) ?></dd>
                <dt><?= h($idLabel) ?></dt><dd class="font-monospace"><?= h($v['id_number']) ?></dd>
              </dl>
              <?php if (strcasecmp(trim($v['legal_name']), $name) !== 0): ?>
                <div class="text-warning-emphasis" style="font-size:.8rem;"><i class="bi bi-exclamation-triangle me-1"></i>Legal name differs from the account name - check the ID carefully.</div>
              <?php endif; ?>
            </div>
            <div class="col-lg-7">
              <div class="d-flex gap-2 flex-wrap">
                <?php foreach ($docs as $key => $label):
                  if ($key === 'back' && !$v['id_back']) continue;
                  $src = 'verification-file.php?id=' . (int) $v['id'] . '&f=' . $key; ?>
                  <a class="verify-doc" href="<?= h($src) ?>" target="_blank" rel="noopener" title="Open full size">
                    <img src="<?= h($src) ?>" alt="<?= h($label) ?>" loading="lazy">
                    <span><?= h($label) ?></span>
                  </a>
                <?php endforeach; ?>
              </div>
            </div>
          </div>

          <div class="d-flex justify-content-end gap-2 mt-3">
            <button class="btn btn-outline-danger btn-sm px-3" data-bs-toggle="modal" data-bs-target="#actionModal"
              data-action="reject_verification" data-id="<?= h($v['id']) ?>" data-tab="verifications" data-variant="danger" data-icon="bi-x-octagon" data-reason="1"
              data-title="Reject this verification?" data-text="<?= h($name) ?> will be notified with your reason and can resubmit.">
              <i class="bi bi-x-lg me-1"></i>Reject</button>
            <button class="btn btn-success btn-sm px-3" data-bs-toggle="modal" data-bs-target="#actionModal"
              data-action="approve_verification" data-id="<?= h($v['id']) ?>" data-tab="verifications" data-variant="success" data-icon="bi-patch-check-fill"
              data-title="Verify <?= h($name) ?>?" data-text="Only approve if the ID is genuine, matches the selfie and the details above. The verified badge goes live immediately.">
              <i class="bi bi-patch-check me-1"></i>Approve &amp; verify</button>
          </div>
        </div>
      <?php endforeach; ?>
    </div>

    <div class="panel">
      <div class="panel-head">
        <h5><i class="bi bi-patch-check-fill me-2 text-success"></i>Verified agents <span class="text-muted fw-normal">(<?= count($verifiedAgents) ?>)</span></h5>
        <div class="search-box"><i class="bi bi-search"></i><input type="text" class="form-control form-control-sm" data-search-target="verified-table" placeholder="Search verified..."></div>
      </div>
      <div class="table-responsive">
        <table class="table" id="verified-table">
          <thead><tr><th>Agent</th><th>Type</th><th>Verified</th><th class="text-end">Actions</th></tr></thead>
          <tbody>
          <?php if (!$verifiedAgents): ?>
            <tr class="empty-row"><td colspan="4">No verified agents yet.</td></tr>
          <?php endif; ?>
          <?php foreach ($verifiedAgents as $a): $an = trim($a['firstname'] . ' ' . $a['lastname']); ?>
            <tr>
              <td>
                <div class="d-flex align-items-center gap-2">
                  <img class="avatar" src="<?= h($a['profileImage'] ?: AVATAR_PLACEHOLDER) ?>" onerror="this.onerror=null;this.src='<?= AVATAR_PLACEHOLDER ?>'">
                  <div><div class="fw-semibold"><?= h($an) ?> <i class="bi bi-patch-check-fill text-primary"></i></div><div class="text-muted" style="font-size:.78rem;"><?= h($a['email']) ?></div></div>
                </div>
              </td>
              <td><span class="badge rounded-pill text-bg-light border"><?= h($a['userType']) ?></span></td>
              <td><?= h(timeAgo($a['verified_at'])) ?></td>
              <td class="text-end">
                <button class="btn btn-icon btn-outline-danger" data-bs-toggle="modal" data-bs-target="#actionModal"
                  data-action="revoke_verification" data-id="<?= h($a['id']) ?>" data-tab="verifications" data-variant="danger" data-icon="bi-patch-minus"
                  data-title="Remove verification?" data-text="<?= h($an) ?>'s verified badge will disappear everywhere. They can apply again." title="Revoke">
                  <i class="bi bi-patch-minus"></i></button>
              </td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- ================= INSPECTIONS ================= -->
  <section class="tab-pane" data-pane="inspections">
    <div class="topbar">
      <div><h3>Pending Inspections</h3><p>Scheduled property inspections awaiting an outcome.</p></div>
    </div>
    <div class="panel">
      <div class="panel-head">
        <h5><i class="bi bi-calendar-check-fill me-2 text-warning"></i>Pending Schedules <span class="text-muted fw-normal">(<?= count($inspections) ?>)</span></h5>
        <div class="search-box"><i class="bi bi-search"></i><input type="text" class="form-control form-control-sm" data-search-target="inspections-table" placeholder="Search inspections..."></div>
      </div>
      <div class="table-responsive">
        <table class="table" id="inspections-table">
          <thead><tr><th>Property</th><th>Customer</th><th>Agent</th><th>Date &amp; Time</th><th>Amount</th><th>Status</th><th class="text-end">Actions</th></tr></thead>
          <tbody>
          <?php if (!$inspections): ?>
            <tr class="empty-row"><td colspan="7">No pending inspections. 🎉</td></tr>
          <?php endif; ?>
          <?php foreach ($inspections as $d): ?>
            <tr>
              <td class="fw-semibold"><?= h($d['property_title']) ?></td>
              <td><?= h($d['customer_name']) ?></td>
              <td><?= h(trim(($d['agent_first'] ?? '') . ' ' . ($d['agent_last'] ?? '')) ?: '—') ?></td>
              <td><?= h($d['inspection_date']) ?> <span class="text-muted"><?= h($d['inspection_time']) ?></span></td>
              <td><?= money($d['amount']) ?></td>
              <td><?= dealBadge($d['dealStatus']) ?></td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <button class="btn btn-icon btn-outline-success" data-bs-toggle="modal" data-bs-target="#actionModal"
                    data-action="update_deal_status" data-decision="Completed" data-id="<?= h($d['id']) ?>" data-tab="inspections" data-variant="success" data-icon="bi-check2-circle"
                    data-title="Mark as completed?" data-text="This inspection for “<?= h($d['property_title']) ?>” will be marked completed." title="Mark completed">
                    <i class="bi bi-check2-circle"></i></button>
                  <button class="btn btn-icon btn-outline-danger" data-bs-toggle="modal" data-bs-target="#actionModal"
                    data-action="update_deal_status" data-decision="Cancelled" data-id="<?= h($d['id']) ?>" data-tab="inspections" data-variant="danger" data-icon="bi-x-circle"
                    data-title="Cancel this inspection?" data-text="This inspection for “<?= h($d['property_title']) ?>” will be marked cancelled." title="Cancel">
                    <i class="bi bi-x-circle"></i></button>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- ================= REPORTS ================= -->
  <section class="tab-pane" data-pane="reports">
    <div class="topbar">
      <div><h3>Reported Agents &amp; Properties</h3><p>Community flags awaiting a decision.</p></div>
    </div>
    <div class="panel">
      <div class="panel-head">
        <h5><i class="bi bi-flag-fill me-2 text-danger"></i>Pending Reports <span class="text-muted fw-normal">(<?= count($reports) ?>)</span></h5>
        <div class="search-box"><i class="bi bi-search"></i><input type="text" class="form-control form-control-sm" data-search-target="reports-table" placeholder="Search reports..."></div>
      </div>
      <div class="table-responsive">
        <table class="table" id="reports-table">
          <thead><tr><th>Case</th><th>Type</th><th>Target</th><th>Reporter</th><th>Reason</th><th>Reported</th><th class="text-end">Actions</th></tr></thead>
          <tbody>
          <?php if (!$reports): ?>
            <tr class="empty-row"><td colspan="7">No pending reports. 🎉</td></tr>
          <?php endif; ?>
          <?php foreach ($reports as $r): ?>
            <tr>
              <td class="fw-semibold"><?= h($r['case_ref']) ?></td>
              <td><span class="badge rounded-pill text-bg-light border"><?= $r['target_type'] === 'property' ? '<i class="bi bi-house-door me-1"></i>Property' : '<i class="bi bi-person me-1"></i>Agent' ?></span></td>
              <td><?= h($r['target_label']) ?></td>
              <td><?= h(trim(($r['reporter_first'] ?? '') . ' ' . ($r['reporter_last'] ?? '')) ?: '—') ?></td>
              <td>
                <div><?= h($reasonLabels[$r['reason_id']] ?? $r['reason_id']) ?></div>
                <div class="text-muted text-truncate" style="max-width:220px;font-size:.78rem;" title="<?= h($r['details']) ?>"><?= h($r['details']) ?></div>
              </td>
              <td><?= h(timeAgo($r['created_at'] ?? null)) ?></td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <button class="btn btn-icon btn-outline-danger" data-bs-toggle="modal" data-bs-target="#actionModal"
                    data-action="review_report" data-decision="actioned" data-id="<?= h($r['id']) ?>" data-tab="reports" data-variant="danger" data-icon="bi-hammer"
                    data-title="Take action on this report?" data-text="This will remove the reported <?= $r['target_type'] === 'property' ? 'listing' : "agent's account and their listings" ?>." title="Take action">
                    <i class="bi bi-hammer"></i></button>
                  <button class="btn btn-icon btn-outline-secondary" data-bs-toggle="modal" data-bs-target="#actionModal"
                    data-action="review_report" data-decision="dismissed" data-id="<?= h($r['id']) ?>" data-tab="reports" data-variant="secondary" data-icon="bi-x-lg"
                    data-title="Dismiss this report?" data-text="No action will be taken and the target will be restored to active if it was auto-flagged." title="Dismiss">
                    <i class="bi bi-x-lg"></i></button>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- ================= PROPERTIES ================= -->
  <section class="tab-pane" data-pane="properties">
    <div class="topbar">
      <div><h3>Properties</h3><p>Every listing uploaded to Aboostoplus.</p></div>
    </div>
    <div class="panel">
      <div class="panel-head">
        <h5><i class="bi bi-house-door-fill me-2 text-primary"></i>All Listings <span class="text-muted fw-normal">(<?= count($properties) ?>)</span></h5>
        <div class="search-box"><i class="bi bi-search"></i><input type="text" class="form-control form-control-sm" data-search-target="properties-table" placeholder="Search properties..."></div>
      </div>
      <div class="table-responsive">
        <table class="table" id="properties-table">
          <thead><tr><th>Listing</th><th>Owner</th><th>Category</th><th>Amount</th><th>Status</th><th>Uploaded</th><th class="text-end">Actions</th></tr></thead>
          <tbody>
          <?php if (!$properties): ?>
            <tr class="empty-row"><td colspan="7">No properties yet.</td></tr>
          <?php endif; ?>
          <?php foreach ($properties as $p): $img = firstImage($p['images'] ?? null); ?>
            <tr>
              <td>
                <div class="d-flex align-items-center gap-2">
                  <img class="thumb" src="<?= h($img ?: THUMB_PLACEHOLDER) ?>" onerror="this.onerror=null;this.src='<?= THUMB_PLACEHOLDER ?>'">
                  <div><div class="fw-semibold text-truncate" style="max-width:220px;"><?= h($p['title']) ?></div><div class="text-muted" style="font-size:.78rem;"><?= h($p['hLocation'] ?? $p['hCity'] ?? '') ?></div></div>
                </div>
              </td>
              <td><div><?= h(trim(($p['owner_first'] ?? '') . ' ' . ($p['owner_last'] ?? '')) ?: '—') ?></div><div class="text-muted" style="font-size:.78rem;"><?= h($p['owner_email'] ?? '') ?></div></td>
              <td><span class="badge rounded-pill text-bg-light border"><?= h($p['category']) ?></span></td>
              <td><?= money($p['amount']) ?></td>
              <td><?= statusBadge($p['status'] ?? 'active') ?></td>
              <td><?= h(timeAgo($p['dateCreated'] ?? null)) ?></td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <?php if (($p['status'] ?? 'active') !== 'active'): ?>
                    <button class="btn btn-icon btn-outline-success" data-bs-toggle="modal" data-bs-target="#actionModal"
                      data-action="restore_property" data-id="<?= h($p['id']) ?>" data-tab="properties" data-variant="success" data-icon="bi-arrow-counterclockwise"
                      data-title="Restore this listing?" data-text="“<?= h($p['title']) ?>” will go back live on the marketplace." title="Restore">
                      <i class="bi bi-arrow-counterclockwise"></i></button>
                  <?php else: ?>
                    <button class="btn btn-icon btn-outline-warning" data-bs-toggle="modal" data-bs-target="#actionModal"
                      data-action="remove_property" data-id="<?= h($p['id']) ?>" data-tab="properties" data-variant="warning" data-icon="bi-eye-slash"
                      data-title="Remove this listing?" data-text="“<?= h($p['title']) ?>” will be hidden from the marketplace immediately." title="Remove">
                      <i class="bi bi-eye-slash"></i></button>
                  <?php endif; ?>
                  <button class="btn btn-icon btn-outline-danger" data-bs-toggle="modal" data-bs-target="#actionModal"
                    data-action="delete_property" data-id="<?= h($p['id']) ?>" data-tab="properties" data-variant="danger" data-icon="bi-trash3"
                    data-title="Delete this listing permanently?" data-text="This cannot be undone. “<?= h($p['title']) ?>” will be permanently deleted." title="Delete">
                    <i class="bi bi-trash3"></i></button>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- ================= PRODUCTS (market_place) ================= -->
  <section class="tab-pane" data-pane="products">
    <div class="topbar">
      <div><h3>Marketplace Products</h3><p>Every product uploaded by users on the marketplace.</p></div>
    </div>
    <div class="panel">
      <div class="panel-head">
        <h5><i class="bi bi-bag-fill me-2 text-primary"></i>All Products <span class="text-muted fw-normal">(<?= count($products) ?>)</span></h5>
        <div class="search-box"><i class="bi bi-search"></i><input type="text" class="form-control form-control-sm" data-search-target="products-table" placeholder="Search products..."></div>
      </div>
      <div class="table-responsive">
        <table class="table" id="products-table">
          <thead><tr><th>Product</th><th>Owner</th><th>Category</th><th>Price</th><th>Location</th><th>Uploaded</th><th class="text-end">Actions</th></tr></thead>
          <tbody>
          <?php if (!$products): ?>
            <tr class="empty-row"><td colspan="7">No products yet.</td></tr>
          <?php endif; ?>
          <?php foreach ($products as $p): $img = firstImage($p['item_images'] ?? null); ?>
            <tr>
              <td>
                <div class="d-flex align-items-center gap-2">
                  <img class="thumb" src="<?= h($img ?: THUMB_PLACEHOLDER) ?>" onerror="this.onerror=null;this.src='<?= THUMB_PLACEHOLDER ?>'">
                  <div class="fw-semibold text-truncate" style="max-width:220px;"><?= h($p['item_name']) ?></div>
                </div>
              </td>
              <td><div><?= h(trim(($p['owner_first'] ?? '') . ' ' . ($p['owner_last'] ?? '')) ?: '—') ?></div><div class="text-muted" style="font-size:.78rem;"><?= h($p['owner_email'] ?? '') ?></div></td>
              <td><span class="badge rounded-pill text-bg-light border"><?= h($p['item_category']) ?></span></td>
              <td><?= money($p['amount']) ?></td>
              <td><?= h($p['item_location'] ?? $p['pState'] ?? '') ?></td>
              <td><?= h(timeAgo($p['createdAt'] ?? null)) ?></td>
              <td class="text-end">
                <button class="btn btn-icon btn-outline-danger" data-bs-toggle="modal" data-bs-target="#actionModal"
                  data-action="delete_product" data-id="<?= h($p['id']) ?>" data-tab="products" data-variant="danger" data-icon="bi-trash3"
                  data-title="Delete this product permanently?" data-text="This cannot be undone. “<?= h($p['item_name']) ?>” will be permanently deleted." title="Delete">
                  <i class="bi bi-trash3"></i></button>
              </td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- ================= NOTIFICATIONS ================= -->
  <section class="tab-pane" data-pane="notifications">
    <div class="topbar">
      <div><h3>Send Push Notification</h3><p>Reach users directly on their device via Firebase Cloud Messaging.</p></div>
    </div>
    <div class="row g-3">
      <div class="col-lg-7">
        <div class="panel">
          <div class="panel-head"><h5><i class="bi bi-send-fill me-2 text-primary"></i>Compose</h5></div>
          <div class="p-4">
            <form method="post" action="actions.php" id="notifyForm">
              <input type="hidden" name="csrf" value="<?= h($csrf) ?>">
              <input type="hidden" name="action" value="send_notification">
              <input type="hidden" name="tab" value="notifications">

              <div class="mb-3">
                <label class="form-label small fw-semibold">Send to</label>
                <select name="audience" id="audienceSelect" class="form-select">
                  <option value="all">All Users (<?= count($notifiableUsers) ?> reachable)</option>
                  <option value="agents">Agents only (<?= count($notifiableAgents) ?> reachable)</option>
                  <option value="users">Regular users only (<?= count($notifiableRegular) ?> reachable)</option>
                  <option value="single">A specific user</option>
                </select>
              </div>

              <div class="mb-3" id="singleUserWrap" style="display:none;">
                <label class="form-label small fw-semibold">User</label>
                <select name="user_id" class="form-select">
                  <?php if (!$notifiableUsers): ?>
                    <option value="">No users with a registered device</option>
                  <?php endif; ?>
                  <?php foreach ($notifiableUsers as $nu): ?>
                    <option value="<?= h($nu['uniqueId']) ?>"><?= h(trim($nu['firstname'] . ' ' . $nu['lastname'])) ?> — <?= h($nu['email']) ?> (<?= h($nu['userType']) ?>)</option>
                  <?php endforeach; ?>
                </select>
              </div>

              <div class="mb-3">
                <label class="form-label small fw-semibold">Title</label>
                <input type="text" name="title" class="form-control" maxlength="100" placeholder="e.g. New feature on Aboostoplus" required>
              </div>

              <div class="mb-4">
                <label class="form-label small fw-semibold">Message</label>
                <textarea name="body" class="form-control" rows="4" maxlength="500" placeholder="Write the notification message..." required></textarea>
              </div>

              <button type="submit" class="btn btn-brand px-4"><i class="bi bi-send-fill me-1"></i> Send Notification</button>
            </form>
          </div>
        </div>
      </div>
      <div class="col-lg-5">
        <div class="panel">
          <div class="panel-head"><h5><i class="bi bi-info-circle-fill me-2 text-primary"></i>Reach</h5></div>
          <div class="p-4 d-flex flex-column gap-2">
            <div class="d-flex justify-content-between"><span class="text-muted">All reachable users</span><strong><?= count($notifiableUsers) ?></strong></div>
            <div class="d-flex justify-content-between"><span class="text-muted">Agents</span><strong><?= count($notifiableAgents) ?></strong></div>
            <div class="d-flex justify-content-between"><span class="text-muted">Regular users</span><strong><?= count($notifiableRegular) ?></strong></div>
            <hr>
            <p class="text-muted small mb-0">Only active accounts with a registered device token can receive a push notification. Suspended accounts and users who have never opened the app on a registered device are excluded automatically.</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- ================= EMAILS (Resend) ================= -->
  <section class="tab-pane" data-pane="emails">
    <div class="topbar">
      <div><h3>Send Email</h3><p>Email users and agents in the Aboostoplus brand template, delivered through Resend.</p></div>
    </div>
    <?php if (!$emailsReady): ?>
      <div class="alert alert-warning">Run <code>lib/call/sql/admin_emails.sql</code> on the database to enable emails (it adds unsubscribe support and send history).</div>
    <?php else: ?>
    <div class="row g-3">
      <div class="col-lg-7">
        <div class="panel">
          <div class="panel-head"><h5><i class="bi bi-envelope-fill me-2 text-primary"></i>Compose</h5></div>
          <div class="p-4">
            <form method="post" action="actions.php" id="emailForm">
              <input type="hidden" name="csrf" value="<?= h($csrf) ?>">
              <input type="hidden" name="action" value="send_email">
              <input type="hidden" name="tab" value="emails">
              <input type="hidden" name="test_only" id="emailTestOnly" value="">

              <div class="mb-3">
                <label class="form-label small fw-semibold">Send to</label>
                <select name="audience" id="emailAudience" class="form-select">
                  <option value="all" data-count="<?= count($subscribed) ?>">All users &amp; agents (<?= count($subscribed) ?>)</option>
                  <option value="agents" data-count="<?= $emailAgents ?>">Agents only (<?= $emailAgents ?>)</option>
                  <option value="users" data-count="<?= $emailRegular ?>">Regular users only (<?= $emailRegular ?>)</option>
                  <option value="single" data-count="1">A specific person</option>
                </select>
              </div>

              <div class="mb-3" id="emailSingleWrap" style="display:none;">
                <label class="form-label small fw-semibold">Person</label>
                <input class="form-control mb-2" type="text" id="emailUserFilter" placeholder="Type to filter by name or email…">
                <select name="user_id" id="emailUserSelect" class="form-select" size="6">
                  <?php foreach ($emailableUsers as $eu): ?>
                    <option value="<?= h($eu['id']) ?>"><?= h(trim($eu['firstname'] . ' ' . $eu['lastname'])) ?> — <?= h($eu['email']) ?> (<?= h($eu['userType']) ?>)<?= (int) $eu['email_opt_out'] ? ' · unsubscribed' : '' ?></option>
                  <?php endforeach; ?>
                </select>
              </div>

              <div class="mb-3">
                <label class="form-label small fw-semibold">Subject</label>
                <input type="text" name="subject" class="form-control" maxlength="150" placeholder="e.g. New on Aboostoplus: check any area’s flood risk" required>
              </div>

              <div class="mb-3">
                <label class="form-label small fw-semibold d-flex justify-content-between">Message
                  <button type="button" class="btn btn-link btn-sm p-0" id="insertFirstName">+ insert {{first_name}}</button></label>
                <textarea name="message" class="form-control" rows="8" maxlength="5000" required
                  placeholder="Hi {{first_name}},&#10;&#10;Write your message here. Leave a blank line between paragraphs."></textarea>
                <div class="form-text">{{first_name}} is replaced with each person’s first name.</div>
              </div>

              <div class="row g-2 mb-4">
                <div class="col-sm-5">
                  <label class="form-label small fw-semibold">Button label <span class="text-muted fw-normal">(optional)</span></label>
                  <input type="text" name="cta_label" class="form-control" maxlength="40" placeholder="e.g. Open Aboostoplus">
                </div>
                <div class="col-sm-7">
                  <label class="form-label small fw-semibold">Button link</label>
                  <input type="url" name="cta_url" class="form-control" maxlength="300" placeholder="https://aboostoplus.com/download">
                </div>
              </div>

              <div class="d-flex flex-wrap gap-2">
                <button type="button" class="btn btn-outline-secondary px-4" id="emailTestBtn"><i class="bi bi-eye me-1"></i> Send test to me</button>
                <button type="button" class="btn btn-brand px-4" id="emailSendBtn"><i class="bi bi-send-fill me-1"></i> Send Email</button>
              </div>
            </form>
          </div>
        </div>
      </div>
      <div class="col-lg-5">
        <div class="panel mb-3">
          <div class="panel-head"><h5><i class="bi bi-people-fill me-2 text-primary"></i>Reach</h5></div>
          <div class="p-4 d-flex flex-column gap-2">
            <div class="d-flex justify-content-between"><span class="text-muted">Subscribed users &amp; agents</span><strong><?= count($subscribed) ?></strong></div>
            <div class="d-flex justify-content-between"><span class="text-muted">Agents</span><strong><?= $emailAgents ?></strong></div>
            <div class="d-flex justify-content-between"><span class="text-muted">Regular users</span><strong><?= $emailRegular ?></strong></div>
            <div class="d-flex justify-content-between"><span class="text-muted">Unsubscribed</span><strong><?= $emailOptedOut ?></strong></div>
            <hr>
            <p class="text-muted small mb-0">Group emails include an unsubscribe link and skip anyone who has unsubscribed, as well as suspended and deleted accounts. Emails to a specific person are treated as account messages and are always delivered.</p>
          </div>
        </div>
        <div class="panel">
          <div class="panel-head"><h5><i class="bi bi-clock-history me-2 text-primary"></i>Recent emails</h5></div>
          <div class="table-responsive">
            <table class="table">
              <thead><tr><th>Subject</th><th>To</th><th>Sent</th><th>When</th></tr></thead>
              <tbody>
              <?php if (!$emailLog): ?>
                <tr class="empty-row"><td colspan="4" class="text-center text-muted py-4">No emails sent yet</td></tr>
              <?php endif; ?>
              <?php foreach ($emailLog as $l): ?>
                <tr>
                  <td class="text-truncate" style="max-width:180px" title="<?= h($l['subject']) ?>"><?= h($l['subject']) ?></td>
                  <td><span class="badge rounded-pill text-bg-light border"><?= h(ucfirst($l['audience'])) ?></span></td>
                  <td><?= (int) $l['sent'] ?><?= (int) $l['failed'] ? ' <span class="text-danger small">(' . (int) $l['failed'] . ' failed)</span>' : '' ?></td>
                  <td class="text-muted small"><?= h(timeAgo($l['created_at'])) ?></td>
                </tr>
              <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    <?php endif; ?>
  </section>

</main>

<!-- Shared confirmation modal for every destructive/status action -->
<div class="modal fade" id="actionModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content" style="border-radius:16px;border:none;">
      <div class="modal-body text-center p-4 p-md-5">
        <div id="actionModalIcon" class="mx-auto mb-3 rounded-circle d-flex align-items-center justify-content-center" style="width:64px;height:64px;">
          <i class="bi fs-3" id="actionModalIconGlyph"></i>
        </div>
        <h5 id="actionModalTitle" class="fw-bold mb-2"></h5>
        <p id="actionModalText" class="text-muted mb-4"></p>
        <form method="post" action="actions.php">
          <input type="hidden" name="csrf" value="<?= h($csrf) ?>">
          <input type="hidden" name="action" id="actionModalActionInput">
          <input type="hidden" name="id" id="actionModalIdInput">
          <input type="hidden" name="decision" id="actionModalDecisionInput">
          <input type="hidden" name="tab" id="actionModalTabInput">
          <div id="actionModalReasonWrap" class="text-start mb-3" style="display:none;">
            <label class="form-label fw-semibold" for="actionModalReason" style="font-size:.85rem;">Reason (sent to the agent)</label>
            <textarea class="form-control" name="reason" id="actionModalReason" rows="3" maxlength="500"
              placeholder="e.g. The ID photo is blurry. Please retake it in good light."></textarea>
          </div>
          <div class="d-flex gap-2 justify-content-center">
            <button type="button" class="btn btn-light px-4" data-bs-dismiss="modal">Cancel</button>
            <button type="submit" id="actionModalConfirmBtn" class="btn px-4">Confirm</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
  // ---- Tab switching (sidebar pills) ----
  const tabs = document.querySelectorAll('#adminTabs .nav-link');
  const panes = document.querySelectorAll('.tab-pane');

  function activateTab(name) {
    tabs.forEach(t => t.classList.toggle('active', t.dataset.tab === name));
    panes.forEach(p => p.classList.toggle('show', p.dataset.pane === name));
  }

  tabs.forEach(t => t.addEventListener('click', e => {
    e.preventDefault();
    activateTab(t.dataset.tab);
    history.replaceState(null, '', '?tab=' + t.dataset.tab);
  }));

  document.querySelectorAll('.jump-tab').forEach(el => el.addEventListener('click', e => {
    e.preventDefault();
    activateTab(el.dataset.tab);
    history.replaceState(null, '', '?tab=' + el.dataset.tab);
  }));

  activateTab(<?= json_encode($activeTab) ?>);

  // ---- Per-table search filter ----
  document.querySelectorAll('[data-search-target]').forEach(input => {
    input.addEventListener('input', () => {
      const table = document.getElementById(input.dataset.searchTarget);
      const term = input.value.trim().toLowerCase();
      table.querySelectorAll('tbody tr').forEach(row => {
        if (row.classList.contains('empty-row')) return;
        row.style.display = row.textContent.toLowerCase().includes(term) ? '' : 'none';
      });
    });
  });

  // ---- Notifications: reveal the specific-user picker only when needed ----
  const audienceSelect = document.getElementById('audienceSelect');
  if (audienceSelect) {
    const singleUserWrap = document.getElementById('singleUserWrap');
    audienceSelect.addEventListener('change', () => {
      singleUserWrap.style.display = audienceSelect.value === 'single' ? '' : 'none';
    });
  }

  // ---- Emails: person picker, {{first_name}}, test send and confirm before a group send ----
  const emailForm = document.getElementById('emailForm');
  if (emailForm) {
    const audience = document.getElementById('emailAudience');
    const singleWrap = document.getElementById('emailSingleWrap');
    const userSelect = document.getElementById('emailUserSelect');
    const testOnly = document.getElementById('emailTestOnly');
    audience.addEventListener('change', () => {
      singleWrap.style.display = audience.value === 'single' ? '' : 'none';
      userSelect.required = audience.value === 'single';
    });
    document.getElementById('emailUserFilter').addEventListener('input', (e) => {
      const term = e.target.value.trim().toLowerCase();
      [...userSelect.options].forEach(o => { o.hidden = term && !o.textContent.toLowerCase().includes(term); });
    });
    document.getElementById('insertFirstName').addEventListener('click', () => {
      const ta = emailForm.querySelector('textarea[name="message"]');
      const pos = ta.selectionStart ?? ta.value.length;
      ta.value = ta.value.slice(0, pos) + '{{first_name}}' + ta.value.slice(pos);
      ta.focus();
    });
    const submit = (isTest) => {
      testOnly.value = isTest ? '1' : '';
      if (!emailForm.reportValidity()) return;
      if (!isTest) {
        const opt = audience.selectedOptions[0];
        const who = audience.value === 'single'
          ? (userSelect.selectedOptions[0] ? userSelect.selectedOptions[0].textContent.split(' — ')[0] : '')
          : opt.dataset.count + ' people';
        if (!who) { alert('Pick a person to email.'); return; }
        if (!confirm('Send this email to ' + who + '? This can’t be undone.')) return;
      }
      emailForm.querySelectorAll('button').forEach(b => b.disabled = true);
      emailForm.submit();
    };
    document.getElementById('emailTestBtn').addEventListener('click', () => submit(true));
    document.getElementById('emailSendBtn').addEventListener('click', () => submit(false));
  }

  // ---- Shared confirm modal ----
  const actionModalEl = document.getElementById('actionModal');
  actionModalEl.addEventListener('show.bs.modal', (event) => {
    const btn = event.relatedTarget;
    document.getElementById('actionModalActionInput').value = btn.dataset.action || '';
    document.getElementById('actionModalIdInput').value = btn.dataset.id || '';
    document.getElementById('actionModalDecisionInput').value = btn.dataset.decision || '';
    document.getElementById('actionModalTabInput').value = btn.dataset.tab || '';
    document.getElementById('actionModalTitle').textContent = btn.dataset.title || 'Are you sure?';
    document.getElementById('actionModalText').textContent = btn.dataset.text || '';

    const needsReason = btn.dataset.reason === '1';
    const reason = document.getElementById('actionModalReason');
    document.getElementById('actionModalReasonWrap').style.display = needsReason ? '' : 'none';
    reason.value = '';
    reason.required = needsReason;

    const variant = btn.dataset.variant || 'primary';
    document.getElementById('actionModalConfirmBtn').className = 'btn px-4 btn-' + variant;

    const iconWrap = document.getElementById('actionModalIcon');
    iconWrap.className = 'mx-auto mb-3 rounded-circle d-flex align-items-center justify-content-center bg-' + variant + '-subtle text-' + variant;
    iconWrap.style.width = '64px';
    iconWrap.style.height = '64px';

    document.getElementById('actionModalIconGlyph').className = 'bi fs-3 ' + (btn.dataset.icon || 'bi-question-circle');
  });
</script>
</body>
</html>
