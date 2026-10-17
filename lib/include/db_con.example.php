<?php




try {
  $userName = "YOUR_DB_USER";
  $password = "YOUR_DB_PASSWORD";
  $pdo = new PDO('mysql:host=localhost;dbname=YOUR_DB_NAME', $userName, $password);
  $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
  $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
  print "Error!: " . $e->getMessage() . "<br>";
  exit();
}
