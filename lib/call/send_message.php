<?php


ini_set('display_errors', 0);
error_reporting(E_ALL);

header('Content-Type: application/json');

require_once dirname(__DIR__) . '/include/db_con.php';

require_once dirname(__DIR__) . '/include/vendor/autoload.php';

global $pdo;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $sender = $_POST['sender_id'] ?? null;
    $receiver = $_POST['receiver_id'] ?? null;
    $message = $_POST['message'] ?? null;
    $sender_name = $_POST['sender_name'] ?? 'Someone';
    $sender_image = $_POST['sender_image'] ?? '';

    if ($sender && $receiver && $message) {
        try {
            file_put_contents('debug_log.txt', "--- NEW MESSAGE DISPATCH CRUISE ---\n", FILE_APPEND);
            // Optional product/property this message is about (sent by the app
            // from listing and product screens). Needs sql/messages_item_ref.sql.
            $item = null;
            if (!empty($_POST['item_title'])) {
                $item = [
                    'item_type' => $_POST['item_type'] ?? '',
                    'item_id' => $_POST['item_id'] ?? '',
                    'item_title' => $_POST['item_title'],
                    'item_image' => $_POST['item_image'] ?? '',
                    'item_amount' => is_numeric($_POST['item_amount'] ?? null) ? $_POST['item_amount'] : null,
                    'item_price_suffix' => $_POST['item_price_suffix'] ?? '',
                ];
            }

            // 1. Persist the message payload to your live MySQL database
            $saved = false;
            if ($item !== null) {
                try {
                    $stmt = $pdo->prepare("INSERT INTO messages (sender_id, receiver_id, message, sender_image, sender_name, item_type, item_id, item_title, item_image, item_amount, item_price_suffix) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                    $stmt->execute([$sender, $receiver, $message, $sender_image, $sender_name, $item['item_type'], $item['item_id'], $item['item_title'], $item['item_image'], $item['item_amount'], $item['item_price_suffix']]);
                    $saved = true;
                } catch (PDOException $e) {
                    // item_* columns not added yet - still deliver the message.
                    file_put_contents('debug_log.txt', "ITEM REF NOT SAVED (run sql/messages_item_ref.sql): " . $e->getMessage() . "\n", FILE_APPEND);
                }
            }
            if (!$saved) {
                $stmt = $pdo->prepare("INSERT INTO messages (sender_id, receiver_id, message,sender_image,sender_name) VALUES (?, ?, ?,?,?)");
                $stmt->execute([$sender, $receiver, $message, $sender_image, $sender_name]);
            }

            // 2. Fetch the recipient's device token from your users/tokens table
            // REPLACE 'users' and column names with your exact database schema names

            // 2. Fetch the recipient's device token
            $tokenStmt = $pdo->prepare("SELECT notification_token FROM users WHERE uniqueId = ? LIMIT 1");
            $tokenStmt->execute([$receiver]);
            $userRow = $tokenStmt->fetch(PDO::FETCH_ASSOC);
            $receiverToken = $userRow ? $userRow['notification_token'] : null;

            // LOG TOKEN STATUS
            if (empty($receiverToken)) {
                file_put_contents('debug_log.txt', "DATABASE STATUS: Found NO token for Receiver ID: $receiver\n", FILE_APPEND);
            } else {
                file_put_contents('debug_log.txt', "DATABASE STATUS: Found Token for Receiver ID $receiver -> Token snippet: " . substr($receiverToken, 0, 15) . "...\n", FILE_APPEND);
            }

            // 3. Dispatch Pusher real-time UI data update events
            $pusher = new Pusher\Pusher(
                "YOUR_PUSHER_KEY",
                "YOUR_PUSHER_SECRET",
                "YOUR_PUSHER_APP_ID",
                array('cluster' => 'YOUR_PUSHER_CLUSTER', 'useTLS' => true)
            );

            $payload = [
                'sender_id' => $sender,
                'receiver_id' => $receiver,
                'message' => $message,
                'sender_name' => $sender_name,
                'sender_image' => $sender_image,
                'timestamp' => date('Y-m-d H:i:s')
            ];
            if ($item !== null) {
                $payload = array_merge($payload, $item);
            }
            $pusher->trigger('chat-room', 'new-message', $payload);

            // 4. 🟢 IF RECIPIENT HAS A VALID DEVICE TOKEN, SEND FIREBASE PUSH NOTIFICATION
            if (!empty($receiverToken)) {
                sendFCMNotification($receiverToken, $sender_name, $message, [
                    // Lets the app open this exact conversation on tap.
                    'type' => 'chat',
                    'sender_id' => (string) $sender,
                    'sender_name' => (string) $sender_name,
                    'sender_image' => (string) $sender_image,
                ]);
            }

            echo json_encode(["status" => "success", "message" => "Sent, saved, and notified."]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["error" => $e->getMessage()]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["error" => "Missing required fields."]);
    }
}

/**
 * 🟢 Core Firebase HTTP v1 push notification implementation helper function
 */
function sendFCMNotification($deviceToken, $senderName, $bodyText, array $data = [])
{
    try {
        $credentialsPath = dirname(__DIR__) . '/include/firebase_credentials.json';

        if (!file_exists($credentialsPath)) {
            file_put_contents('debug_log.txt', "FCM ERROR: Credentials file missing.\n", FILE_APPEND);
            return false;
        }

        // 1. Read JSON contents manually
        $serviceAccount = json_decode(file_get_contents($credentialsPath), true);
        $clientEmail = $serviceAccount['client_email'];
        $privateKey = $serviceAccount['private_key'];
        $projectId = $serviceAccount['project_id'];


        require_once __DIR__ . '/FcmNotificationSender.php';

        $sender = new FcmNotificationSender(
            $projectId,
            $credentialsPath,
        );


        $result = $sender->sendToDevice(
            $deviceToken,
            $senderName,
            $bodyText,
            $data
        );
        // (Was print_r($result), which dumped debug output into the JSON
        // response the app receives.)
        return $result;
    } catch (Throwable $e) {
        file_put_contents('debug_log.txt', "FCM CRITICAL SYSTEM EXCEPTION: " . $e->getMessage() . "\n\n", FILE_APPEND);
        return false;
    }
}
