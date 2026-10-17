<?php
// social_login.php
//
// "Continue with Google / Apple" for the mobile app.
//
// Request (JSON):  { provider: "google"|"apple", id_token, name? }
// Response:        same shape as login.php — { success, token, expires_at, user }
//
// The ID token is the only thing trusted: its RS256 signature is checked
// against the provider's published keys, and the email / subject come from
// the verified token, never from the request body. `name` is only used to
// fill in a brand-new account (Apple sends the name to the app once, not
// in the token).
//
// Account matching, in order:
//   1. social_identities (provider + subject) -> that user
//   2. a users row with the same verified email -> link it, then log in
//   3. otherwise create a new "User" account and link it
//
// Needs the social_identities table: see sql/social_identities.sql.
declare(strict_types=1);

header('Content-Type: application/json');
require_once __DIR__ . '/cors.php';
require __DIR__ . '/../include/db_con.php';

const TOKEN_LIFETIME_DAYS = 30;

// Audiences the ID tokens must be issued for.
// Google: the Web OAuth client ID the app passes as serverClientId
//   (SocialAuthConfig.googleWebClientId in lib/const/social_auth_config.dart).
// Apple: the iOS bundle ID.
const GOOGLE_AUDIENCES = [
    'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // Web client (serverClientId)
    'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // iOS client
];
const APPLE_AUDIENCES = [
    'com.aboostoplus.app',
];

const PROVIDERS = [
    'google' => [
        'jwks'    => 'https://www.googleapis.com/oauth2/v3/certs',
        'issuers' => ['https://accounts.google.com', 'accounts.google.com'],
    ],
    'apple' => [
        'jwks'    => 'https://appleid.apple.com/auth/keys',
        'issuers' => ['https://appleid.apple.com'],
    ],
];

function fail(int $status, string $message): void
{
    http_response_code($status);
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
}

function b64url_decode(string $data): string
{
    $decoded = base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4), true);
    if ($decoded === false) {
        throw new RuntimeException('Malformed token');
    }
    return $decoded;
}

/** Fetches the provider's signing keys, cached on disk for 6 hours. */
function fetch_jwks(string $provider, bool $forceRefresh = false): array
{
    $cache = sys_get_temp_dir() . "/aboostoplus_jwks_{$provider}.json";
    if (!$forceRefresh && is_file($cache) && filemtime($cache) > time() - 6 * 3600) {
        $keys = json_decode((string) file_get_contents($cache), true);
        if (is_array($keys['keys'] ?? null)) {
            return $keys['keys'];
        }
    }

    $ctx  = stream_context_create(['http' => ['timeout' => 8]]);
    $body = @file_get_contents(PROVIDERS[$provider]['jwks'], false, $ctx);
    $json = $body === false ? null : json_decode($body, true);
    if (!is_array($json['keys'] ?? null)) {
        throw new RuntimeException('Could not load signing keys');
    }
    @file_put_contents($cache, $body, LOCK_EX);
    return $json['keys'];
}

/** DER length prefix. */
function der_len(int $len): string
{
    if ($len < 0x80) {
        return chr($len);
    }
    $bytes = ltrim(pack('N', $len), "\0");
    return chr(0x80 | strlen($bytes)) . $bytes;
}

/** Builds a PEM public key from an RSA JWK (n, e). */
function jwk_to_pem(array $jwk): string
{
    $int = function (string $bytes): string {
        if (ord($bytes[0]) > 0x7f) {
            $bytes = "\0" . $bytes; // keep the INTEGER positive
        }
        return "\x02" . der_len(strlen($bytes)) . $bytes;
    };
    $rsaKey   = $int(b64url_decode($jwk['n'])) . $int(b64url_decode($jwk['e']));
    $rsaKey   = "\x30" . der_len(strlen($rsaKey)) . $rsaKey;
    $bitStr   = "\x03" . der_len(strlen($rsaKey) + 1) . "\0" . $rsaKey;
    $algId    = "\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01\x05\x00"; // rsaEncryption
    $spki     = "\x30" . der_len(strlen($algId . $bitStr)) . $algId . $bitStr;
    return "-----BEGIN PUBLIC KEY-----\n" . chunk_split(base64_encode($spki), 64, "\n") . "-----END PUBLIC KEY-----\n";
}

/** Verifies the token and returns its claims, or throws. */
function verify_id_token(string $provider, string $jwt, array $audiences): array
{
    $parts = explode('.', $jwt);
    if (count($parts) !== 3) {
        throw new RuntimeException('Malformed token');
    }
    [$h64, $p64, $s64] = $parts;
    $header = json_decode(b64url_decode($h64), true);
    $claims = json_decode(b64url_decode($p64), true);
    if (!is_array($header) || !is_array($claims) || ($header['alg'] ?? '') !== 'RS256' || empty($header['kid'])) {
        throw new RuntimeException('Unsupported token');
    }

    $findKey = function (array $keys) use ($header): ?array {
        foreach ($keys as $k) {
            if (($k['kid'] ?? '') === $header['kid'] && ($k['kty'] ?? '') === 'RSA') {
                return $k;
            }
        }
        return null;
    };
    // Providers rotate keys; refetch once if the kid isn't in the cache.
    $jwk = $findKey(fetch_jwks($provider)) ?? $findKey(fetch_jwks($provider, true));
    if ($jwk === null) {
        throw new RuntimeException('Unknown signing key');
    }

    $ok = openssl_verify("$h64.$p64", b64url_decode($s64), jwk_to_pem($jwk), OPENSSL_ALGO_SHA256);
    if ($ok !== 1) {
        throw new RuntimeException('Bad signature');
    }

    $now = time();
    $aud = (array) ($claims['aud'] ?? []);
    if (!in_array($claims['iss'] ?? '', PROVIDERS[$provider]['issuers'], true)) {
        throw new RuntimeException('Wrong issuer');
    }
    if (!array_intersect($aud, $audiences)) {
        throw new RuntimeException('Wrong audience');
    }
    if (($claims['exp'] ?? 0) < $now - 60 || ($claims['iat'] ?? 0) > $now + 300) {
        throw new RuntimeException('Token expired');
    }
    if (empty($claims['sub'])) {
        throw new RuntimeException('Token has no subject');
    }
    return $claims;
}

function generate_unique_id(): string
{
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    $id = '';
    for ($i = 0; $i < 10; $i++) {
        $id .= $chars[random_int(0, strlen($chars) - 1)];
    }
    return $id;
}

// ---------------------------------------------------------------------------

$input    = json_decode((string) file_get_contents('php://input'), true) ?: [];
$provider = $input['provider'] ?? '';
$idToken  = $input['id_token'] ?? '';
$name     = trim((string) ($input['name'] ?? ''));

if (!isset(PROVIDERS[$provider]) || !is_string($idToken) || $idToken === '') {
    fail(422, 'Missing provider or token');
}

try {
    $claims = verify_id_token($provider, $idToken, $provider === 'google' ? GOOGLE_AUDIENCES : APPLE_AUDIENCES);
} catch (Throwable $e) {
    error_log("social_login.php: $provider token rejected: " . $e->getMessage());
    fail(401, 'Could not verify your ' . ucfirst($provider) . ' sign-in. Please try again.');
}

$subject = (string) $claims['sub'];
$email   = strtolower(trim((string) ($claims['email'] ?? '')));
// Google marks unverified addresses; Apple only issues verified ones
// (including private relay addresses).
$emailVerified = $provider === 'apple'
    ? $email !== ''
    : ($claims['email_verified'] ?? false) === true || ($claims['email_verified'] ?? '') === 'true';

try {
    // 1. Already linked?
    $stmt = $pdo->prepare(
        'SELECT u.* FROM social_identities s INNER JOIN users u ON u.id = s.user_id
         WHERE s.provider = ? AND s.subject = ?'
    );
    $stmt->execute([$provider, $subject]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        if ($email === '' || !$emailVerified) {
            fail(422, 'Your ' . ucfirst($provider) . ' account did not share a verified email address.');
        }

        $pdo->beginTransaction();

        // 2. Existing account with this email -> link it.
        $stmt = $pdo->prepare('SELECT * FROM users WHERE LOWER(email) = ? LIMIT 1');
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // 3. Brand-new account.
        if (!$user) {
            $first = (string) ($claims['given_name'] ?? '');
            $last  = (string) ($claims['family_name'] ?? '');
            if ($first === '' && $name !== '') {
                [$first, $last] = array_pad(explode(' ', $name, 2), 2, '');
            }
            if ($first === '') {
                $first = ucfirst(strtok($email, '@') ?: 'User');
            }
            $picture = (string) ($claims['picture'] ?? '');
            if ($picture === '') {
                $picture = 'https://www.w3schools.com/howto/img_avatar.png';
            }

            $pdo->prepare(
                'INSERT INTO users
                   (uniqueId, firstname, lastname, email, profileImage, userType, uAddress, uState, city, leadUid, phone, notification_token, user_pwd)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            )->execute([
                generate_unique_id(),
                mb_substr($first, 0, 100),
                mb_substr($last, 0, 100),
                $email,
                $picture,
                'User',          // agents still sign up through the full agent flow
                '', '', '', '',  // uAddress, uState, city, leadUid
                '',              // phone
                '',              // notification_token — the app syncs it after login
                // No password: a random hash nobody knows. "Forgot password"
                // still lets them set one for email login later.
                password_hash(bin2hex(random_bytes(32)), PASSWORD_BCRYPT),
            ]);

            $stmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
            $stmt->execute([(int) $pdo->lastInsertId()]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
        }

        $pdo->prepare('INSERT INTO social_identities (user_id, provider, subject, email) VALUES (?, ?, ?, ?)')
            ->execute([$user['id'], $provider, $subject, $email]);

        $pdo->commit();
    }

    if (($user['account_status'] ?? 'active') !== 'active') {
        fail(403, 'Account is ' . $user['account_status']);
    }

    $rawToken  = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+' . TOKEN_LIFETIME_DAYS . ' days'));
    $pdo->prepare('INSERT INTO auth_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)')
        ->execute([$user['id'], hash('sha256', $rawToken), $expiresAt]);

    $user['user_pwd'] = ''; // never return the hash

    echo json_encode([
        'success'    => true,
        'token'      => $rawToken,
        'expires_at' => $expiresAt,
        'user'       => $user,
    ]);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('social_login.php: ' . $e->getMessage());
    fail(500, 'Could not sign you in right now. Please try again.');
}
