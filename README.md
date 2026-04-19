# UniServe

A smart student service app that centralizes campus services for university students. Built with Flutter, targeting iOS and Android.

## Features

| Feature | Description |
|---|---|
| **Home Dashboard** | Weather widget, quick access to all features |
| **Campus Hub** | Campus map, room bookings, events calendar |
| **Emergency Contacts** | One-tap calls to security, medical, and maintenance |
| **Report Issues** | Submit maintenance issues with photo and description |
| **Lost & Found** | Report or search for lost items with photo upload |
| **Campus Map** | Locate lecture halls, cafeteria, library, dorms via GPS |
| **Schedule** | Personal class/event timetable |
| **Study Rooms** | Browse and book available study rooms |
| **Notifications** | Campus events, shuttle delays, maintenance updates |
| **Profile & Settings** | Account management, dark mode, app preferences |

## Tech Stack

- **Flutter** 3.x / **Dart SDK** ^3.10.7
- **State Management** — Provider
- **Routing** — GoRouter
- **Backend** — Supabase (auth, Postgres, storage)
- **Local Cache** — sqflite (offline read support)
- **Maps** — flutter_map + OpenStreetMap (no API key required)
- **Weather** — wttr.in API (no API key required)
- **Camera** — image_picker
- **GPS** — geolocator
- **Phone/URL** — url_launcher
- **Notifications** — flutter_local_notifications + timezone
- **QR** — mobile_scanner + qr_flutter
- **Speech** — speech_to_text
- **Connectivity** — connectivity_plus

## Project Structure

```
lib/
├── main.dart                        # Entry point, MultiProvider setup
├── config/
│   ├── theme.dart                   # Material 3 light/dark themes
│   ├── router.dart                  # GoRouter route definitions
│   ├── supabase_config.dart         # Supabase credentials
│   ├── emergency_contacts_data.dart
│   └── campus_locations_data.dart
├── models/                          # Data classes (toMap/fromMap/fromSupabase)
├── providers/                       # ChangeNotifier state management
│   ├── auth_provider.dart
│   ├── theme_provider.dart
│   ├── issues_provider.dart
│   ├── lost_found_provider.dart
│   ├── notifications_provider.dart
│   ├── weather_provider.dart
│   ├── schedule_provider.dart
│   ├── study_rooms_provider.dart
│   ├── events_provider.dart
│   ├── connectivity_provider.dart
│   └── app_settings_provider.dart
├── services/
│   ├── supabase_service.dart        # Supabase auth, DB, storage
│   ├── database_service.dart        # sqflite local cache
│   ├── weather_service.dart         # wttr.in API client
│   └── notification_service.dart
└── screens/
    ├── splash/
    ├── auth/
    ├── home/
    ├── campus/                      # Campus Hub (map, bookings, events)
    ├── campus_map/
    ├── emergency/
    ├── report_issue/
    ├── lost_found/
    ├── notifications/
    ├── profile/
    ├── settings/
    └── shell/                       # Bottom nav shell
```

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x (`flutter --version`)
- A Supabase project (get URL and anon key from your project dashboard)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/UniServe.git
   cd UniServe
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add your Supabase credentials in `lib/config/supabase_config.dart`:
   ```dart
   class SupabaseConfig {
     static const String url = 'YOUR_SUPABASE_URL';
     static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Common Commands

```bash
flutter run                          # Run on connected device/emulator
flutter run -d chrome                # Run on web
flutter run -d macos                 # Run on macOS desktop
flutter test                         # Run all tests
flutter analyze                      # Lint / static analysis
flutter build apk                    # Build Android APK
flutter build ios                    # Build iOS
flutter clean                        # Clean build artifacts
```

## Required Permissions

| Permission | Used For |
|---|---|
| Camera | Report Issues, Lost & Found photo upload |
| Location | Campus Map GPS positioning |
| Notifications | Push/local notifications |
| Phone | Emergency contact calls |
