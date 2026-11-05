# WARKA NEWS

A Flutter starter for a bilingual English/Amharic news app.

## Included
- English and Amharic interface toggle (top right).
- News feed with clearly marked sample/demo stories.
- Save stories locally during the current app session.
- News tip form with optional anonymous submission and photo/video attachment.
- Private message form for contacting the publisher.
- Supabase integration hooks and starter SQL with row-level security.

## Important status
This is a working UI starter, not a published production app. News cards are sample content. Tip and message submission require a Supabase project and the SQL setup below. A secure publisher login/dashboard, article publishing tools, push notifications, persistent bookmarks, and full Amharic editorial review are next build steps.

## Run locally
1. Install Flutter SDK and Android Studio on a computer.
2. Extract this project.
3. In the project folder run `flutter pub get`.
4. Run in demo mode: `flutter run`.
5. To connect Supabase:
   - Create a Supabase project.
   - Open SQL Editor and run `supabase/schema.sql`.
   - Create a **private** Storage bucket named `news-tips`.
   - Add suitable storage upload policies. Do not make tips publicly readable.
   - Run:
     `flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY`

Use only the Supabase anon/public key in the mobile app. Never put a service-role key in the app.

## Before public launch
- Add staff authentication and staff-only policies for reading tips/messages and managing articles.
- Add a publisher dashboard with role-based access.
- Add moderation, rate limits, file size/type limits, malware scanning, and abuse reporting.
- Configure Firebase Cloud Messaging for breaking-news notifications.
- Test Amharic text rendering on real Android devices.
- Publish a privacy policy and terms, and obtain consent for personal data/media submissions.

## Build an APK with GitHub Actions (no local Flutter installation)
1. Create a GitHub repository and upload the extracted project files.
2. Open the repository's **Actions** tab.
3. Select **Build Android APK** and choose **Run workflow**.
4. When the run finishes, open it and download the `warka-news-release-apk` artifact.
5. Extract the downloaded artifact to get `app-release.apk`.

This workflow builds the demo APK. Add Supabase credentials as secure GitHub Actions secrets and update the workflow before enabling live submissions.
