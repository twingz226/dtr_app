# OJT Daily Time Record App

A modern, offline-first Flutter app for OJT students to track their daily time records.

## Features

- **Home Dashboard** — Greet user, one-tap Time In / Time Out, OJT progress bar, recent records
- **DTR Records** — Monthly calendar view, edit remarks & status, delete records
- **Summary** — Donut chart for OJT completion %, bar chart for monthly hours, weekly breakdown
- **Profile** — Student info, school, company, supervisor, required hours

## Tech Stack

| Package | Purpose |
|---|---|
| `sqflite` | Local SQLite offline storage |
| `google_fonts` | Plus Jakarta Sans typography |
| `flutter_animate` | Smooth entry animations |
| `fl_chart` | Donut + bar charts |
| `intl` | Date/time formatting |
| `shared_preferences` | Lightweight key-value storage |

## Setup

1. Copy all files into your Flutter project
2. Run `flutter pub get`
3. Run `flutter run`

## Project Structure

```
lib/
├── main.dart                    # App entry + bottom nav
├── theme/
│   └── app_theme.dart           # Dark theme: Navy + Teal + Orange
├── models/
│   ├── student_profile.dart     # Profile data model
│   └── dtr_record.dart          # DTR entry data model
├── database/
│   └── database_helper.dart     # SQLite CRUD operations
├── screens/
│   ├── home_screen.dart         # Dashboard + clock in/out
│   ├── records_screen.dart      # Monthly records list
│   ├── summary_screen.dart      # Charts & statistics
│   └── profile_screen.dart      # Student profile setup
└── widgets/
    ├── stat_card.dart           # Reusable stat tile
    └── recent_record_tile.dart  # Record list item
```

## Color Palette

- Background: `#0A1628` (Deep Navy)
- Card: `#111E33`
- Primary Accent: `#00C9A7` (Teal)
- Secondary Accent: `#FF6B35` (Orange)
- Success: `#00E096`
- Error: `#FF4C6A`
