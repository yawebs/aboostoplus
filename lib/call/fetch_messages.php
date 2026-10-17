<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '../../include/db_con.php';
global $pdo;

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $sender_id = $_GET['sender_id'] ?? null;
    $receiver_id = $_GET['receiver_id'] ?? null;

    if ($sender_id !== null && $receiver_id !== null) {
        try {
            // 🟢 USE POSITIONAL QUESTION MARKS TO ELIMINATE PARSING KEY MISMATCHES
            $where = "FROM messages
                      WHERE (sender_id = ? AND receiver_id = ?)
                         OR (sender_id = ? AND receiver_id = ?)
                      ORDER BY id ASC";
            // Pass the values sequentially to match the order of the question marks
            $params = [
                $sender_id,   // First ? -> sender_id
                $receiver_id, // Second ? -> receiver_id
                $receiver_id, // Third ? -> sender_id (flipped case)
                $sender_id    // Fourth ? -> receiver_id (flipped case)
            ];

            try {
                // Includes the product/property each message refers to.
                $stmt = $pdo->prepare("SELECT sender_id, receiver_id, message, created_at AS timestamp,
                      item_type, item_id, item_title, item_image, item_amount, item_price_suffix $where");
                $stmt->execute($params);
            } catch (PDOException $e) {
                // item_* columns not added yet (sql/messages_item_ref.sql).
                $stmt = $pdo->prepare("SELECT sender_id, receiver_id, message, created_at AS timestamp $where");
                $stmt->execute($params);
            }

            $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                "status" => "success",
                "data" => $messages
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["error" => $e->getMessage()]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["error" => "Missing identification attributes (sender_id or receiver_id)."]);
    }
} else {
    http_response_code(405);
    echo json_encode(["error" => "Method Not Allowed."]);
}
