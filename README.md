# Salama Care

A Flutter-based healthcare appointment management application that connects patients with doctors. Salama Care supports three user roles — **patients**, **doctors**, and **admins** — with a Supabase backend for authentication, database, and real-time features.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Database Schema](#database-schema)
- [User Flows](#user-flows)
- [Appointment Status Workflow](#appointment-status-workflow)
- [Edge Functions](#edge-functions)
- [Getting Started](#getting-started)
- [Build & Distribution](#build--distribution)
- [Environment & Secrets](#environment--secrets)

---

## Overview

Salama Care is a multi-role healthcare platform designed to streamline appointment booking and management between patients and doctors. Patients can browse doctors, book appointments, manage their medical profile, and receive email confirmations. Doctors can manage their schedule, availability, and patient records. Admins have full oversight of all platform activity.

---

## Features

### Patient
- Role-based registration and login
- Multi-step medical profile setup (personal info, medical history, emergency contacts, insurance)
- Browse and search doctors by name or specialty
- Book appointments with available time slot selection
- View upcoming and past appointments
- Upload and manage personal medical documents
- Receive email confirmation on booking
- Appointment reminders via email

### Doctor
- Complete doctor profile (license, bio, education, specialties, languages, fees)
- Dashboard with today's schedule and statistics
- Toggle availability and accepting-patients status
- Weekly calendar view
- Manage appointment statuses (confirm, complete, no-show, cancel)
- Access patient medical records and documents
- Manage blocked time slots and availability windows

### Admin
- Full access to all users, appointments, and platform data
- Manage doctors and patients
- View analytics and no-show tracking
- Role and permission management

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Dart) |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| Email | Resend API |
| Charts | fl_chart |
| Calendar | table_calendar |
| Navigation | google_nav_bar |
| PDF | pdf + printing + syncfusion_flutter_pdfviewer |
| File Handling | image_picker, file_picker |
| Fonts | DM Sans, IBM Plex Mono (Google Fonts) |

---

## Architecture

The project follows a **feature-based architecture** with clear separation between UI, business logic, and data layers.

### Design Principles
- **Feature isolation**: Each feature (auth, patient, doctor, appointments, admin) is self-contained
- **Layer separation**: Every feature has `screens/`, `services/`, and `models/` subdirectories
- **Core module**: Shared utilities, constants, and configuration live in `core/`
- **Service pattern**: All Supabase queries go through service classes — never directly from UI
- **Absolute imports**: All imports use `package:signup/` prefix

### Color System

Defined in `lib/core/constants/colors.dart`:

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#2ec0f9` | Main brand color (bright cyan) |
| Secondary | `#67aaf9` | Sky blue accents |
| Tertiary | `#9bbdf9` | Light blue |
| Quaternary | `#c4e0f9` | Very light blue backgrounds |
| Accent | `#b95f89` | Rose pink highlights |

Standard gradients: `AppColors.primaryGradient`, `AppColors.subtleGradient`, `AppColors.accentGradient`

---

## Folder Structure

```
lib/
├── main.dart                          # App entry point
├── core/                              # Shared/global functionality
│   ├── config/
│   │   └── supabase_config.dart       # Supabase URL & anon key
│   ├── services/
│   │   └── supabase_service.dart      # Supabase client wrapper
│   ├── constants/
│   │   ├── categories.dart
│   │   ├── colors.dart                # AppColors design system
│   │   └── doctors.dart
│   └── widgets/                       # Shared reusable widgets
│
└── features/
    ├── authentication/
    │   ├── screens/
    │   │   ├── firstpage.dart         # Welcome/landing screen
    │   │   ├── loginScreen.dart
    │   │   ├── Signup.dart
    │   │   └── ForgotPasswordScreen.dart
    │   └── services/
    │       └── supabase_auth_service.dart
    │
    ├── patient/
    │   ├── screens/
    │   │   ├── Homepage.dart          # Doctor browsing + health tips
    │   │   ├── MedicalForm.dart       # 4-step profile setup
    │   │   ├── ProfileScreen.dart
    │   │   └── PatientDocumentsScreen.dart
    │   ├── services/
    │   │   └── patient_service.dart
    │   └── widgets/
    │
    ├── doctor/
    │   ├── screens/
    │   │   ├── DoctorDashboard.dart
    │   │   ├── DoctorProfileForm.dart
    │   │   ├── DoctorAppointmentsScreen.dart
    │   │   ├── AvailabilityManagementScreen.dart
    │   │   ├── BlockedTimeSlotsScreen.dart
    │   │   ├── PatientMedicalRecord.dart
    │   │   ├── PatientDocumentsViewScreen.dart
    │   │   ├── calendar_view.dart
    │   │   └── weekly_schedule_view.dart
    │   ├── services/
    │   │   └── doctor_service.dart
    │   └── widgets/
    │
    ├── appointments/
    │   ├── screens/
    │   │   ├── appointmentsScreen.dart
    │   │   ├── BookAppointmentPage.dart   # 5-step booking flow
    │   │   ├── AddAppointmentNoteDialog.dart
    │   │   └── ViewAppointmentNotesScreen.dart
    │   ├── services/
    │   │   └── appointment_service.dart
    │   └── widgets/
    │
    ├── admin/
    │   └── screens/                   # Admin dashboard and management
    │
    └── notifications/
        └── services/
```

---

## Database Schema

### Core Tables
| Table | Description |
|-------|-------------|
| `users` | Base user records with role (patient/doctor/admin) |
| `patients` | Patient profiles linked to users |
| `doctors` | Doctor profiles with bio, fees, experience |
| `admins` | Admin records |

### Patient Tables
| Table | Description |
|-------|-------------|
| `medical_history` | Patient medical background |
| `emergency_contacts` | Emergency contact info |
| `insurance_information` | Insurance details |
| `patient_documents` | Uploaded files/documents |

### Doctor Tables
| Table | Description |
|-------|-------------|
| `specialties` | Medical specialties list |
| `doctor_specialties` | Doctor ↔ specialty mapping (primary + additional) |
| `doctor_availability` | Weekly recurring availability windows |
| `blocked_time_slots` | Specific blocked dates/times |

### Appointment Tables
| Table | Description |
|-------|-------------|
| `appointments` | Core appointment records |
| `appointment_types` | Types of appointments |
| `appointment_notes` | Notes added by doctor/patient |
| `appointment_reminders` | Scheduled reminder records |

### Supporting Tables
`payments`, `waitlist`, `notifications`, `clinic_settings`

### Row Level Security (RLS)
All tables have RLS enabled:
- **Patients** can only read/write their own data
- **Doctors** can read their appointments and assigned patients
- **Admins** have full access to all tables

### Applied Migrations
| Migration | Description |
|-----------|-------------|
| `20251230232800` | populate_medical_specialties (7 specialties) |
| `20251231004428` | add_doctor_education_languages |

**Available Specialties**: General Practice, Cardiology, Pediatrics, Orthopedics, Dermatology, Neurology, Gynecology

---

## User Flows

### Patient Flow
1. **Register/Login** — Role-based signup with email/password via Supabase Auth
2. **Complete Profile** — 4-step form: Personal Info → Medical Info → Emergency Contact → Insurance
3. **Browse Doctors** — Search by name, filter by specialty, view ratings and fees
4. **Book Appointment** — 5-step flow: Select doctor → Date → Time slot → Reason → Confirm
5. **Manage Appointments** — View upcoming/past, access notes and records

### Doctor Flow
1. **Login** — Same authentication as patients
2. **Complete Profile** — License, bio, specialties, availability, fees
3. **Dashboard** — Stats, next appointment countdown, patient search
4. **Manage Appointments** — Confirm, complete, mark no-show, cancel; access patient records
5. **Manage Availability** — Set weekly windows and block specific times

### Admin Flow
- Full platform visibility via admin dashboard
- Manage users, appointments, permissions, and analytics

---

## Appointment Status Workflow

```
scheduled → confirmed → checked_in → in_progress → completed
                ↓
           cancelled / no_show
```

| Status | Meaning |
|--------|---------|
| `scheduled` | Initial booking created |
| `confirmed` | Doctor/patient confirmed |
| `checked_in` | Patient arrived at clinic |
| `in_progress` | Consultation started |
| `completed` | Visit finished |
| `cancelled` | Appointment cancelled |
| `no_show` | Patient didn't attend (increments `patients.no_show_count`) |

---

## Edge Functions

Deployed on Supabase Edge Functions (Deno runtime):

| Function | Trigger | Description |
|----------|---------|-------------|
| `send-appointment-confirmation` | Database webhook on INSERT | Sends booking confirmation email via Resend |
| `send-appointment-reminders` | Cron job | Sends reminder emails before upcoming appointments |
| `send-appointment-reschedule` | Manual call | Notifies patient of reschedule |
| `create-user` | Auth hook | Initializes user record on signup |

> **Note**: Email sending requires a verified domain configured in Resend. The `onboarding@resend.dev` sender is restricted to the Resend account owner's email only.

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK ^3.5.3
- A Supabase project
- A Resend account with a verified domain (for email)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd salama-care
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**

   Create or update `lib/core/config/supabase_config.dart`:
   ```dart
   class SupabaseConfig {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```
   > Do not commit this file with real credentials. Add it to `.gitignore`.

4. **Set Edge Function secrets** in Supabase dashboard:
   - `RESEND_API_KEY` — your Resend API key

5. **Run the app**
   ```bash
   flutter run
   flutter run -d windows
   flutter run -d chrome
   ```

### Common Commands

```bash
flutter run              # Run in debug mode
flutter build windows    # Build Windows desktop app
flutter build apk        # Build Android APK
flutter build web        # Build web app
flutter analyze          # Run linter
flutter test             # Run tests
flutter pub upgrade      # Upgrade dependencies
```

---

## Build & Distribution

### Windows Desktop
```bash
flutter build windows --release
```

Output location:
```
build/windows/x64/runner/Release/
```

Send the **entire `Release/` folder** (zip it) — the app requires the DLLs and `data/` folder alongside the `.exe`.

Recipients need:
- Windows 10 or 11 (64-bit)
- Visual C++ Redistributable (if they get DLL errors)

### Android
```bash
flutter build apk --release
```

### Web
```bash
flutter build web
```

---

## Environment & Secrets

The following should **never** be committed to version control:

| File | Contains |
|------|---------|
| `lib/core/config/supabase_config.dart` | Supabase URL and anon key |
| `.mcp.json` | MCP server configuration / API keys |
| `android/app/google-services.json` | Firebase credentials (removed) |

Add sensitive files to `.gitignore` and use environment variables or a secrets manager for production deployments.

---

## Contributing

1. Follow the feature-based folder structure
2. Place screens in `features/{feature}/screens/`, services in `features/{feature}/services/`
3. Use `AppColors` constants for all UI colors
4. Always access Supabase through service classes, never directly from widgets
5. Handle loading, empty, and error states for all data views
6. Test with all three roles: patient, doctor, admin
