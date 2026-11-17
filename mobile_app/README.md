# EventConnect QR - Flutter Android Mobile Application

The complete Flutter mobile application for **EventConnect QR**, connecting directly to the Django REST API backend.

---

## 📱 Features Included
- **Authentication**: JWT/Token Login, Registration, and Secure Session Storage.
- **Event Management**: Create events, view hosted invitations, and access venue directions.
- **QR Code Scanner**: Native high-speed camera scanner using `mobile_scanner`. Detects event and business QR codes instantly.
- **QR Code Generator & Display**: On-screen high-contrast QR display using `qr_flutter`.
- **Digital Business Profiles**: Browse businesses, view catalogs with prices, direct phone calls, and WhatsApp chat integration.
- **Subscriptions & Plans**: Dynamic pricing tiers and direct checkout links.

---

## 📦 How to Build the Android APK File

### Method 1: Local Build (Using Flutter on Windows)
If you have the Flutter SDK and Android Studio / SDK installed on your PC:

1. Open PowerShell and navigate to this folder:
   ```powershell
   cd "c:\Users\omics\Downloads\New folder\qr\mobile_app"
   ```

2. Fetch Flutter packages:
   ```powershell
   flutter pub get
   ```

3. Build the release APK:
   ```powershell
   flutter build apk --release
   ```

4. Your compiled APK file will be generated at:
   ```
   mobile_app\build\app\outputs\flutter-apk\app-release.apk
   ```

---

### Method 2: Instant Cloud Build (GitHub Actions)
If you do not have the 5GB Android SDK installed on your local computer, you can compile the APK automatically in the cloud:

1. Push this project to GitHub.
2. Open the **Actions** tab on your GitHub repository.
3. Select the **Build Android APK** workflow and click **Run workflow**.
4. In ~3 minutes, the compiled `EventConnectQR-release-apk` will be available in the **Artifacts** section for immediate download.

---

## 📲 How to Install the APK on Your Phone
1. Transfer `app-release.apk` to your Android device via WhatsApp, Google Drive, or USB cable.
2. Tap on the file on your phone.
3. If prompted, allow "Install from Unknown Sources".
4. Open **EventConnect QR** and log in with your test credentials:
   - Email: `ravi@sample.eventconnect.com`
   - Password: `Test@1234`
