<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '../../include/db_con.php';
global $pdo;

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $current_user_id = $_GET['current_user_id'] ?? null;

    if ($current_user_id !== null) {
        try {
            // Complex subquery to extract ONLY the latest message row per unique conversation partner
            $query = "SELECT m1.*, 
                             DATE_FORMAT(m1.created_at, '%d %b') as date_label
                      FROM messages m1
                      JOIN (
                          SELECT LEAST(sender_id, receiver_id) as user_a, 
                                 GREATEST(sender_id, receiver_id) as user_b, 
                                 MAX(id) as max_id
                          FROM messages
                          WHERE sender_id = ? OR receiver_id = ?
                          GROUP BY user_a, user_b
                      ) m2 ON m1.id = m2.max_id
                      ORDER BY m1.id DESC";

            $stmt = $pdo->prepare($query);
            $stmt->execute([$current_user_id, $current_user_id]);
            $rawConversations = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Look up every chat partner's real profile in one query. Previously a
            // conversation where I sent the last message showed "Chat Partner <id>"
            // and MY OWN photo (sender_image), since the partner was never looked up.
            $partnerIds = [];
            foreach ($rawConversations as $chat) {
                $partnerIds[] = ($chat['sender_id'] == $current_user_id) ? $chat['receiver_id'] : $chat['sender_id'];
            }
            $partners = [];
            $partnerIds = array_values(array_unique($partnerIds));
            if ($partnerIds) {
                $in = implode(',', array_fill(0, count($partnerIds), '?'));
                $userStmt = $pdo->prepare("SELECT uniqueId, firstname, lastname, profileImage, userType FROM users WHERE uniqueId IN ($in)");
                $userStmt->execute($partnerIds);
                foreach ($userStmt->fetchAll(PDO::FETCH_ASSOC) as $u) {
                    $partners[$u['uniqueId']] = $u;
                }
            }

            $processedConversations = [];
            foreach ($rawConversations as $chat) {
                // Determine if the chat partner is the sender or receiver relative to current user
                $isMeSender = ($chat['sender_id'] == $current_user_id);
                $partner_id = $isMeSender ? $chat['receiver_id'] : $chat['sender_id'];
                $partner = $partners[$partner_id] ?? null;

                if ($partner) {
                    $name = trim(($partner['firstname'] ?? '') . ' ' . ($partner['lastname'] ?? ''));
                    $image = $partner['profileImage'] ?? '';
                } else {
                    // Unknown/deleted account: best effort from the message row.
                    $name = $isMeSender ? '' : ($chat['sender_name'] ?? '');
                    $image = $isMeSender ? '' : ($chat['sender_image'] ?? '');
                }

                $processedConversations[] = [
                    'partner_id' => $partner_id,
                    'name' => $name !== '' ? $name : 'Aboostoplus user',
                    'profile_image' => $image ?? '',
                    'user_type' => $partner['userType'] ?? '',
                    // Kept with the "You: " prefix for older app versions;
                    // newer ones use message + last_from_me instead.
                    'last_message' => $isMeSender ? "You: " . $chat['message'] : $chat['message'],
                    'message' => $chat['message'],
                    'last_from_me' => $isMeSender,
                    'timestamp' => $chat['created_at'] ?? null,
                    'date' => $chat['date_label'],
                    // No read receipts yet: true means "they sent the last message".
                    'is_unread' => !$isMeSender,
                    // Product/property the latest message referred to, if stored
                    // (needs sql/messages_item_ref.sql).
                    'item_title' => $chat['item_title'] ?? null,
                    'item_image' => $chat['item_image'] ?? null,
                ];
            }

            echo json_encode([
                "status" => "success",
                "data" => $processedConversations
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["error" => $e->getMessage()]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["error" => "Missing current_user_id parameter."]);
    }
}
