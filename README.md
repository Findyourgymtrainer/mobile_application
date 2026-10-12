# Find Your Gym Trainer

A Flutter mobile app (Android and iOS) for finding and booking gym trainers and tracking workouts. It implements the requirements in [`requirements.md`](spec/requirements.md) as a **fully working local prototype**: all data is stored on the device with `shared_preferences`, so no backend or internet connection is needed.

## What the app does

| Role | Features |
|------|----------|
| **Member** | Browse, search and filter trainers (specialty, location, gender, price, rating) · trainer profiles with certifications and reviews · favourites · book, reschedule and cancel sessions · workout log with a 7-day volume chart · rate and review trainers · in-app chat · notifications |
| **Trainer** | Dashboard with booking requests (accept/decline) and upcoming sessions · weekly availability and blocked dates · edit trainer profile · client list with workout history and workout assignment · chat |
| **Admin** | Approve or reject new trainers · remove trainers · remove reviews |

Everyone can log in with email/password, phone OTP (demo) or Google (demo), reset a forgotten password, switch between light/dark/system theme, edit their profile and delete their account.

### Demo accounts

Tap a chip on the login screen, or type the credentials. The password for all of them is `demo123`.

| Role | Email |
|------|-------|
| Member | `member@demo.com` |
| Trainer | `trainer@demo.com` |
| Admin | `admin@demo.com` |

Phone sign-in accepts any 10-digit number with OTP `123456`. "Continue with Google" is a simulated sign-in.

### Not implemented yet

- Payments and earnings (FR-21, FR-22 – marked Optional / Phase 2 in the requirements).
- A real backend, real push notifications (in-app notifications are used instead), real Google OAuth / SMS OTP, and photo uploads (avatars show initials).

---

## Local startup guide

### 1. Prerequisites

| Tool | Needed for | Check with |
|------|-----------|------------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/mobile) 3.47+ (includes Dart) | everything | `flutter --version` |
| [Git](https://git-scm.com/) | cloning | `git --version` |
| [Android Studio](https://developer.android.com/studio) + Android SDK | running on Android emulator/phone | `flutter doctor` |
| Google Chrome | quick preview in a browser (no Android setup) | `flutter devices` |
| Xcode (macOS only) | running on iPhone / iOS simulator | `flutter doctor` |

### 2. Get the code

```bash
git clone https://github.com/Findyourgymtrainer/mobile_application.git
cd mobile_application
flutter pub get
```

### 3. Check your setup

```bash
flutter doctor
```

Fix anything marked with a red ✗ for the platform you want to run on. (Visual Studio is only needed for Windows desktop apps and can be ignored.)

### 4. Run the app

**Option A – Chrome (fastest, no Android SDK needed)**

```bash
flutter run -d chrome
```

**Option B – Android emulator from Android Studio**

1. Open Android Studio and finish the first-run wizard so it installs the **Android SDK**.
2. Tell Flutter where the SDK is (once): `flutter config --android-sdk "C:\Users\<you>\AppData\Local\Android\Sdk"` and accept licenses with `flutter doctor --android-licenses`.
3. In Android Studio choose **File → Open** and select this project folder. Install the **Flutter** and **Dart** plugins if prompted (**Settings → Plugins**).
4. Open **Device Manager** (phone icon on the right) → **Create Device** (e.g. Pixel 7, a recent system image) → start it with ▶.
5. Pick the emulator in the device dropdown in the toolbar and press **Run ▶** (or `Shift+F10`).

Or from a terminal:

```bash
flutter emulators                   # list emulators
flutter emulators --launch <id>     # start one
flutter run                         # run on the running emulator
```

> The emulator needs hardware virtualization (Intel VT-x / AMD-V) enabled in the BIOS, and works best with 8 GB+ RAM. If your machine struggles, use a real phone.

**Option C – a real Android phone**

1. On the phone: **Settings → About phone**, tap **Build number** 7 times, then enable **Developer options → USB debugging**.
2. Connect it with USB and accept the prompt on the phone.
3. Run `flutter devices` to confirm it appears, then `flutter run`.

**Option D – iPhone / iOS simulator** (macOS with Xcode only)

```bash
open -a Simulator
flutter run
```

### 5. Handy commands while developing

| Command / key | What it does |
|---------------|--------------|
| `r` in the `flutter run` terminal | Hot reload |
| `R` | Hot restart |
| `q` | Quit |
| `flutter test` | Run the automated tests |
| `flutter analyze` | Static analysis / lint |
| `flutter build apk` | Build an installable Android APK (needs the Android SDK) |
| `flutter clean && flutter pub get` | Fix odd build problems |

To wipe the sample data, use **Profile → Reset demo data** in the app.

### Troubleshooting

- **"Unable to locate Android SDK"** – finish Android Studio's setup wizard, then run the `flutter config --android-sdk ...` command above.
- **"cmdline-tools component is missing"** – Android Studio → **SDK Manager → SDK Tools** → tick *Android SDK Command-line Tools* → Apply.
- **Emulator will not start / is very slow** – enable virtualization in the BIOS and close other heavy apps, or use Chrome / a real phone.
- **No devices listed** – run `flutter doctor -v` and `flutter devices`; for phones, re-check USB debugging and the cable.

---

## Project structure

```
lib/
  main.dart            App entry point, theme, root navigation
  models.dart          Data classes (users, trainers, bookings, workouts, reviews, messages)
  seed.dart            Demo trainers, accounts and reviews
  app_state.dart       App state + local persistence (swap for an API/backend later)
  screens/
    auth.dart          Onboarding, login, sign-up, forgot password, phone OTP
    shell.dart         Role-based bottom navigation
    member.dart        Home, trainer search/filters, trainer profile, booking, workouts
    trainer.dart       Dashboard, availability, clients
    admin.dart         Trainer approvals and review moderation
    messages.dart      Notifications, conversations and chat
    profile.dart       Profile, settings, trainer profile editor
    common.dart        Shared widgets and formatting helpers
test/widget_test.dart  Unit and widget tests
docs/screenshots/    App screenshots
spec/requirements.md   Product requirements
```

## Tech stack

Flutter 3.47 · Dart 3.13 · Material 3 · `shared_preferences` for local storage. Package id: `com.findyourgymtrainer.gym_trainer`.
