<?php
// login.php — admin sign-in. Only users with userType = 'Admin' may pass.
declare(strict_types=1);

require __DIR__ . '/auth.php';
require __DIR__ . '/../../include/db_con.php';

if (!empty($_SESSION['admin_id'])) {
    header('Location: index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCsrf($_POST['csrf'] ?? null)) {
        $error = 'Your session expired, please try again.';
    } else {
        $email = trim($_POST['email'] ?? '');
        $password = $_POST['password'] ?? '';

        $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ? AND userType = 'Admin' LIMIT 1");
        $stmt->execute([$email]);
        $admin = $stmt->fetch();

        if (!$admin || !password_verify($password, $admin['user_pwd'])) {
            $error = 'Invalid email or password.';
        } elseif ($admin['account_status'] !== 'active') {
            $error = 'This admin account is ' . $admin['account_status'] . '.';
        } else {
            session_regenerate_id(true);
            $_SESSION['admin_id'] = (int) $admin['id'];
            $_SESSION['admin_name'] = trim($admin['firstname'] . ' ' . $admin['lastname']);
            header('Location: index.php');
            exit;
        }
    }
}

$csrf = csrfToken();
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin Login · Aboostoplus</title>
<link rel="icon" type="image/png" href="assets/icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
<style>
  :root{
    --brand:#4f46e5;
    --brand-dark:#3730a3;
  }
  *{font-family:'Inter',system-ui,sans-serif;}
  body{
    min-height:100vh;
    display:flex;
    align-items:center;
    justify-content:center;
    background:radial-gradient(circle at 20% 20%, #4f46e5 0%, #1e1b4b 45%, #0f172a 100%);
    padding:16px;
  }
  .login-card{
    width:100%;
    max-width:400px;
    border:none;
    border-radius:20px;
    box-shadow:0 30px 60px -20px rgba(15,23,42,.5);
    overflow:hidden;
  }
  .login-brand{
    width:64px;height:64px;
    display:flex;align-items:center;justify-content:center;
    margin:0 auto 16px;
  }
  .login-brand img{width:100%;height:100%;object-fit:contain;}
  .form-control:focus{border-color:var(--brand);box-shadow:0 0 0 .2rem rgba(79,70,229,.15);}
  .btn-brand{
    background:linear-gradient(135deg,var(--brand),var(--brand-dark));
    border:none;color:#fff;font-weight:600;
  }
  .btn-brand:hover{color:#fff;filter:brightness(1.08);}
</style>
</head>
<body>
  <div class="card login-card">
    <div class="card-body p-4 p-md-5">
      <div class="login-brand"><img src="assets/icon.png" alt="Aboostoplus"></div>
      <h4 class="text-center fw-bold mb-1">Aboostoplus Admin</h4>
      <p class="text-center text-muted mb-4">Sign in to manage the marketplace</p>

      <?php if ($error): ?>
        <div class="alert alert-danger py-2 small"><i class="bi bi-exclamation-triangle me-1"></i><?= h($error) ?></div>
      <?php endif; ?>

      <form method="post" novalidate>
        <input type="hidden" name="csrf" value="<?= h($csrf) ?>">
        <div class="mb-3">
          <label class="form-label small fw-semibold">Email address</label>
          <input type="email" name="email" class="form-control form-control-lg" placeholder="you@example.com" required autofocus>
        </div>
        <div class="mb-4">
          <label class="form-label small fw-semibold">Password</label>
          <input type="password" name="password" class="form-control form-control-lg" placeholder="••••••••" required>
        </div>
        <button type="submit" class="btn btn-brand btn-lg w-100">Sign In</button>
      </form>
    </div>
  </div>
</body>
</html>
