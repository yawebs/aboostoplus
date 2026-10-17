<?php

class FcmNotificationSender
{
    private string $projectId;
    private string $serviceAccountPath;

    public function __construct(string $projectId, string $serviceAccountPath)
    {
        $this->projectId = $projectId;
        $this->serviceAccountPath = $serviceAccountPath;
    }

    /**
     * Get a short-lived OAuth2 access token using the service account.
     */
    private function getAccessToken(): string
    {
        $client = new \Google\Client();
        $client->setAuthConfig($this->serviceAccountPath);
        $client->addScope('https://www.googleapis.com/auth/firebase.messaging');

        $token = $client->fetchAccessTokenWithAssertion();

        if (isset($token['error'])) {
            throw new \Exception('Failed to get access token: ' . $token['error_description']);
        }

        return $token['access_token'];
    }

    /**
     * Send a notification to a single device token.
     *
     * @param string $deviceToken FCM registration token from the Flutter app
     * @param string $title
     * @param string $body
     * @param array  $data Optional custom key-value data payload (all values must be strings)
     * @return array Response from FCM
     */
    public function sendToDevice(string $deviceToken, string $title, string $body, array $data = []): array
    {
        $accessToken = $this->getAccessToken();

        $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

        // FCM requires all "data" values to be strings
        $stringData = array_map('strval', $data);

        $message = [
            'message' => [
                'token' => $deviceToken,
                'notification' => [
                    'title' => $title,
                    'body'  => $body,
                ],
                'data' => $stringData,
                'android' => [
                    'priority' => 'high',
                ],
                'apns' => [
                    'headers' => [
                        'apns-priority' => '10',
                    ],
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                        ],
                    ],
                ],
            ],
        ];

        return $this->postToFcm($url, $accessToken, $message);
    }

    /**
     * Send the same notification to many device tokens, reusing a single
     * OAuth access token instead of fetching a fresh one per recipient
     * (sendToDevice() in a loop would do one Google auth round-trip per
     * user, which is far too slow for a broadcast to more than a handful
     * of people).
     *
     * @param string[] $deviceTokens
     * @return array Keyed by device token: either the FCM response, or
     *               ['error' => string] if that one send failed — a bad
     *               token doesn't abort the rest of the batch.
     */
    public function sendToMultipleDevices(array $deviceTokens, string $title, string $body, array $data = []): array
    {
        $accessToken = $this->getAccessToken();
        $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";
        $stringData = array_map('strval', $data);

        $results = [];
        foreach ($deviceTokens as $deviceToken) {
            $message = [
                'message' => [
                    'token' => $deviceToken,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'data' => $stringData,
                    'android' => [
                        'priority' => 'high',
                    ],
                    'apns' => [
                        'headers' => [
                            'apns-priority' => '10',
                        ],
                        'payload' => [
                            'aps' => [
                                'sound' => 'default',
                            ],
                        ],
                    ],
                ],
            ];

            try {
                $results[$deviceToken] = $this->postToFcm($url, $accessToken, $message);
            } catch (\Exception $e) {
                $results[$deviceToken] = ['error' => $e->getMessage()];
            }
        }

        return $results;
    }

    /**
     * Send a notification to a topic instead of a single device.
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = []): array
    {
        $accessToken = $this->getAccessToken();

        $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

        $stringData = array_map('strval', $data);

        $message = [
            'message' => [
                'topic' => $topic,
                'notification' => [
                    'title' => $title,
                    'body'  => $body,
                ],
                'data' => $stringData,
            ],
        ];

        return $this->postToFcm($url, $accessToken, $message);
    }

    /**
     * Internal helper to perform the cURL POST request.
     */
    private function postToFcm(string $url, string $accessToken, array $message): array
    {
        $ch = curl_init($url);

        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS => json_encode($message),
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($error) {
            throw new \Exception('cURL error: ' . $error);
        }

        $decoded = json_decode($response, true);

        if ($httpCode !== 200) {
            throw new \Exception('FCM error (' . $httpCode . '): ' . $response);
        }

        return $decoded;
    }
}
