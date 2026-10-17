# Aboostoplus: setup checklist

This project was cloned from Zegicon and rebranded to **Aboostoplus** (`aboostoplus.com`).
All Zegicon names, app IDs and keys have been removed. Before the app can run, it needs its **own** accounts and keys.
Search the project for `YOUR_` to find every placeholder.

## Already done
- App name **Aboostoplus** on Android, iOS, web and Windows.
- App ID / bundle ID **`com.aboostoplus.app`** (Android `MainActivity` moved to `kotlin/com/aboostoplus/app/`).
- Every `zegicon.com` address is now `aboostoplus.com`: API (`https://aboostoplus.com/api`), emails, website, unsubscribe and delete-account links.
- Removed: Zegicon's Firebase config files, Firebase admin credentials, database credentials, Zegicon promo/marketing material and the Zegicon promo video on the website.
- Secret keys that were built into the app (Pusher secret, Flutterwave secret key) are gone. Those must only ever live on the server.

## 1. Backend server (aboostoplus.com)
1. Create a MySQL database and import the schema from your current database (structure only: `mysqldump --no-data`), or run the files in `lib/call/sql/`.
2. Copy `lib/include/db_con.example.php` to `lib/include/db_con.php` on the server and fill in the database name, user and password. **Never commit `db_con.php`**; it's git-ignored.
3. Upload `lib/call/` to `https://aboostoplus.com/api/` and `lib/func/` + `lib/include/` alongside it, matching the Zegicon server layout.
4. Email: copy `lib/include/mail_config.example.php` to `mail_config.php`, add a **Resend** API key and verify `aboostoplus.com` in Resend.
5. Upload `website/` to the site root.

## 2. Firebase (push notifications, storage)
1. Create a new Firebase project, e.g. "Aboostoplus".
2. Add an Android app with package **`com.aboostoplus.app`** and an iOS app with bundle ID **`com.aboostoplus.app`**.
3. In this folder run `flutterfire configure`. That recreates `lib/firebase_options.dart`, `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.
4. For server-sent notifications, download a service-account key and save it on the server as `lib/include/firebase_credentials.json`.

## 3. Third-party keys (search `YOUR_`)
| Service | Where | What to put |
|---|---|---|
| Google Maps | `lib/const/constant.dart` (`GoogleApiKey`), `android/app/src/main/AndroidManifest.xml` | New Google Cloud API key, restricted to the new app IDs |
| Google sign-in | `lib/const/social_auth_config.dart`, `lib/call/social_login.php` | OAuth client IDs from the new Firebase/Google Cloud project |
| Sign in with Apple | Apple Developer account | Enable for bundle ID `com.aboostoplus.app` |
| Pusher (chat) | `lib/const/constant.dart` (app id, key, cluster), `lib/call/send_message.php` (key, **secret**, app id, cluster) | New Pusher app. The secret goes **only** in the PHP file |
| Flutterwave | `lib/services/payment.dart` | Public keys only. Secret keys belong on the server |
| Gemini (AI area insights) | `lib/func/helper.php` (`$apiKey`) | New key from Google AI Studio |
| Resend | `lib/include/mail_config.php` on the server | New API key |

## 4. Branding assets (still show the Zegicon logo)
- Replace `assets/images/logo.png`, `assets/images/logo-icon.png` and `assets/icon/icon.png`, then run `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
- Website screenshots in `website/assets/img/screen-*.jpg` are Zegicon app screenshots. Retake them from the Aboostoplus app.
- Add a social share image as `website/assets/img/og-image.png` (1200×628) and put back the `og:image` tag in `website/index.html`.
- Colours (plum and gold) are unchanged; edit `lib/theme/app_palette.dart` and `lib/theme/app_theme.dart` to restyle.

## 5. Store listings
- Create new listings in Google Play Console and App Store Connect for `com.aboostoplus.app`.
- When the App Store listing exists, replace `YOUR_APP_STORE_ID` (website pages and `lib/call/app-version.php`).
- Privacy policy, terms and delete-account pages are ready at `aboostoplus.com/privacy-policy/`, `/terms-and-conditions/` and `/delete-account/`. Review the company details in them before submitting.

## Notes
- The Dart package is still named `eafind` internally (`package:eafind/...`). Users never see this, and renaming it would touch every import.
- Don't reuse Zegicon's signing keystore. Create a new upload key for this app.
