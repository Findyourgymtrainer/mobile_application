# Find Your Gym Trainer – Requirements (Sample)

> Sample draft. Replace or edit the items below as the real requirements are confirmed.

## 1. Overview
A cross-platform mobile app (Android and iOS) that helps users find and book gym trainers, and lets trainers manage their profile, availability and clients.

## 2. User Roles
- **Member:** searches for trainers, books sessions, tracks workouts.
- **Trainer:** manages profile, availability, bookings and client progress.
- **Admin:** approves trainers, manages content and handles reports.

## 3. Tech Stack
- Flutter 3.47 / Dart 3.13
- Package: `com.findyourgymtrainer.gym_trainer`
- Backend: to be decided (e.g. Firebase or a REST API)
- Source control: GitHub – `Findyourgymtrainer/mobile_application`
- Design: [Figma file](https://www.figma.com/file/EYujF7bOCNu9bD7tZEiUn9?node-id=0:1&p=f&t=sLmJXVNjluikI5py-0&locale=en&type=design) – screens mirror the implemented app

## 4. Functional Requirements

### 4.1 Authentication
| ID | Requirement |
|----|-------------|
| FR-1 | User can sign up and log in with email and password. |
| FR-2 | User can log in with phone number (OTP) or Google. |
| FR-3 | User chooses a role (Member or Trainer) at sign-up. |
| FR-4 | User can reset a forgotten password. |

### 4.2 Trainer Discovery (Member)
| ID | Requirement |
|----|-------------|
| FR-5 | Member can browse and search trainers by name. |
| FR-6 | Member can filter trainers by specialty, location, price, rating and gender. |
| FR-7 | Member can view a trainer profile with bio, certifications, photos, reviews and rates. |
| FR-8 | Member can save trainers to a favourites list. |

### 4.3 Booking
| ID | Requirement |
|----|-------------|
| FR-9 | Member can view a trainer's available time slots. |
| FR-10 | Member can book, reschedule and cancel a session. |
| FR-11 | Trainer can accept or decline booking requests. |
| FR-12 | Both parties receive push notifications for booking changes and reminders. |

### 4.4 Trainer Profile & Availability
| ID | Requirement |
|----|-------------|
| FR-13 | Trainer can create and edit a profile (bio, specialties, certifications, rates, photos). |
| FR-14 | Trainer can set weekly availability and block out dates. |
| FR-15 | Trainer can view upcoming and past sessions. |

### 4.5 Workout Tracking
| ID | Requirement |
|----|-------------|
| FR-16 | Member can log workouts (exercise, sets, reps, weight, date). |
| FR-17 | Member can view workout history and progress charts. |
| FR-18 | Trainer can assign a workout plan to a client. |

### 4.6 Reviews & Communication
| ID | Requirement |
|----|-------------|
| FR-19 | Member can rate and review a trainer after a completed session. |
| FR-20 | Member and trainer can chat in-app. |

### 4.7 Payments (Optional / Phase 2)
| ID | Requirement |
|----|-------------|
| FR-21 | Member can pay for a session in-app. |
| FR-22 | Trainer can view earnings and payout history. |

### 4.8 Admin
| ID | Requirement |
|----|-------------|
| FR-23 | Admin can approve or reject trainer accounts. |
| FR-24 | Admin can remove inappropriate reviews or accounts. |

## 5. Non-Functional Requirements
- **Platforms:** Android 8.0+ and iOS 14+.
- **Performance:** screens load in under 2 seconds on a typical 4G connection.
- **Security:** passwords never stored in plain text; all traffic over HTTPS; personal data access limited by role.
- **Privacy:** user can delete their account and data.
- **Usability:** supports light and dark mode; works on small and large phone screens.
- **Accessibility:** readable font sizes, sufficient colour contrast, screen-reader labels.
- **Reliability:** graceful handling of no network; clear error messages.
- **Maintainability:** follows Flutter lint rules (`analysis_options.yaml`); core logic covered by tests.

## 6. Key Screens
1. Splash / onboarding
2. Login / sign-up
3. Home (featured trainers, upcoming sessions)
4. Search and filters
5. Trainer profile
6. Booking calendar and confirmation
7. My bookings
8. Workout log and progress
9. Chat
10. Member / trainer profile and settings
11. Trainer dashboard (requests, availability, clients)

## 7. Data Model (Draft)
- **User:** id, name, email, phone, role, photoUrl, createdAt
- **TrainerProfile:** userId, bio, specialties[], certifications[], hourlyRate, location, ratingAvg
- **Availability:** trainerId, dayOfWeek, startTime, endTime
- **Booking:** id, memberId, trainerId, startTime, endTime, status (pending / confirmed / cancelled / completed)
- **Workout:** id, memberId, date, exercises[ {name, sets, reps, weightKg} ]
- **Review:** id, bookingId, memberId, trainerId, rating (1–5), comment
- **Message:** id, senderId, receiverId, text, sentAt

## 8. Development Setup
```
flutter pub get
flutter run            # needs an Android device/emulator or Chrome (-d chrome)
flutter test
flutter build apk
```
Requires the Android SDK (install via Android Studio) for Android builds.

## 9. Milestones (Sample)
1. **M1 – Foundation:** project setup, navigation, theme, authentication.
2. **M2 – Trainer discovery:** search, filters, trainer profiles.
3. **M3 – Booking:** availability, booking flow, notifications.
4. **M4 – Tracking and reviews:** workout log, charts, ratings.
5. **M5 – Polish and release:** chat, testing, store submission. Payments if confirmed.

## 10. Open Questions
- Which backend should be used (Firebase, custom REST API)?
- Are payments required in the first release?
- Is there a Figma design to follow?
- Which cities or regions will the app launch in?
