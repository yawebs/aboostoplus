<?php
// Copy this file to mail_config.php (same folder) on the server and fill it in.
// mail_config.php is git-ignored so the API key never gets committed.
//
// 1. Create an API key at https://resend.com/api-keys (permission: "Sending access").
// 2. Verify aboostoplus.com at https://resend.com/domains, otherwise Resend only
//    delivers to your own account email.

return [
    'resend_api_key' => 're_xxxxxxxxxxxxxxxxxxxxxxxx',
    'from'           => 'Aboostoplus <no-reply@aboostoplus.com>',
    'reply_to'       => 'support@aboostoplus.com',
];
