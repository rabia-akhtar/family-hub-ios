# Family Hub — iOS App

A family dashboard iOS app built with SwiftUI. Tasks, rewards, groceries, budget, calendar, and weather — all backed by Google Sheets so every family member stays in sync across devices.

## Features

| Tab | What it does |
|-----|-------------|
| **Home** | Weather snapshot, today's tasks, upcoming events, points leaderboard |
| **Tasks** | Add/complete tasks with a gamified points system (chore/house/cats = 5 pts, other = 3 pts). Milestones: ✨ → ⭐ (250) → 🥇 (500) → 🏆 (750) |
| **Rewards** | Redeem earned points for rewards you define |
| **Calendar** | Google Calendar events for the next 30 days |
| **Weather** | Current conditions, UV, wind, 24-hour hourly, 7-day forecast (Open-Meteo, no API key) |
| **Groceries** | Shared grocery checklist |
| **Budget** | Expense tracker by category with monthly totals |

## How data syncs

All data lives in **two Google Sheets** in the signed-in Google account:

- **Family Hub Data** — Tasks, Rewards, Points, Groceries
- **Family Hub Budget** — Budget entries (its own separate spreadsheet)

Both sheets are created automatically on first launch. Any family member who signs into the same Google account on any device will find and use the same sheets — no manual sharing needed.

## Setup

### 1. Google Cloud project

1. Go to [console.cloud.google.com](https://console.cloud.google.com) and create a project.
2. Enable these APIs:
   - Google Sheets API
   - Google Drive API
   - Google Calendar API
3. Go to **APIs & Services → OAuth consent screen** and configure it (External, add test users while in development).
4. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
   - Application type: **iOS**
   - Bundle ID: `com.familyhub.FamilyHub` (or whatever you set in `project.yml`)
5. Download the `GoogleService-Info.plist` and note the **Client ID** and **Reversed Client ID**.

### 2. Configure the Xcode project

Open `project.yml` and fill in:

```yaml
CLIENT_ID: "your-client-id.apps.googleusercontent.com"
REVERSED_CLIENT_ID: "com.googleusercontent.apps.your-client-id"
```

### 3. Generate and open the Xcode project

```bash
make setup        # installs xcodegen via Homebrew if needed, then generates FamilyHub.xcodeproj
open FamilyHub.xcodeproj
```

### 4. Build and run

Select your device or simulator in Xcode and press **⌘R**.

On first launch, sign in with Google. The app will:
1. Search your Drive for existing "Family Hub Data" and "Family Hub Budget" spreadsheets.
2. Create them if not found, with headers pre-filled.
3. Any other device signing into the same Google account will find and connect to the same sheets.

## Multi-device

Sign into the same Google account on multiple iPhones/iPads. The app uses the **Google Drive API** (`drive.readonly` scope) to search for sheets by name, so every device connects to the shared data rather than creating its own copy.

## OAuth Scopes requested

| Scope | Why |
|-------|-----|
| `spreadsheets` | Read and write task, reward, grocery, budget data |
| `drive.file` | Create the spreadsheets on first launch |
| `drive.readonly` | Search Drive for existing spreadsheets (enables multi-device) |
| `calendar.readonly` | Read upcoming calendar events |

## Default location

Weather defaults to New York City (40.7128, -74.0060). Change `defaultLatitude` / `defaultLongitude` in `FamilyHub/Config/AppConfig.swift`.

## Requirements

- iOS 17+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
