# ReelIQ

ReelIQ is a comprehensive, AI-powered Instagram Reel optimization platform built with Flutter and Dart. It is designed to maximize viewer engagement, predict retention profiles, analyze and score hooks, and offer customized structural recommendations. ReelIQ uses Material 3 to provide a sleek, modern, and dark-themed user experience.

## Comprehensive Features

### 1. Authentication & Onboarding
- **Gatekeeper Auth:** Secure login and sign-up flows using Firebase Auth. Supports both standard Email/Password authentication and Google Sign-in.
- **Onboarding Flow:** An intuitive onboarding sequence for new users to set up their profiles and understand the core features.

### 2. Dashboard & Analytics
- **Dynamic Dashboard Tracker:** A centralized hub to monitor total processed reels, track average engagement score trends, and access a scrollable log of prior AI scans.
- **Reports:** Detailed, structured reports of historic uploads and their respective engagement predictions.

### 3. Media Upload & Processing
- **Interactive Upload Sandbox:** Select video clips directly from the local device gallery using Image Picker.
- **Integrated Video Player:** Play back video selections right within the app before initiating the AI metric calculations.

### 4. AI Feedback & Analysis
- **Detailed AI Feedback:** View calculated viral scores out of 100 on interactive visual gauges.
- **Linguistic Grading:** Receive text-based feedback and custom pacing suggestions.

### 5. Hook A/B Testing Lab
- **Multi-Concept Testing:** Input three custom hook variations simultaneously.
- **Simulations:** Run linguistic analysis simulations to compare score breakdowns side-by-side and confidently identify the most effective hook before publishing.

### 6. Integrations & Payments
- **Instagram Integration:** Seamless features built to specifically optimize the Instagram reels algorithm.
- **Payments & Subscriptions:** In-App Purchases and Razorpay integration to handle premium features and tiered subscriptions.

### 7. User Profile Management
- **Creator Profile:** View personal user telemetry, manage account settings, and access support features through embedded webviews and URL launchers.

### 8. AI Creator Copilot (Premium Strategy Engine)
- **Multi-Stage Generation:** Generates comprehensive 7, 30, or 90 day content plans including weekly growth roadmaps, hooks, captions, and checklists.
- **Dynamic Memory:** The pipeline retains context across sequential generation steps to ensure zero duplicated ideas or hooks across an entire campaign.
- **Strategy Decks:** Automatically exports professional, consulting-grade PDF strategy documents (including gap analyses and KPI tables) directly from the backend.
- **Live Streaming:** Real-time generation progress updates piped directly to the UI via Server-Sent Events (SSE).

---

## Technology Stack & Dependencies

**Core framework:**
- Flutter & Dart
- Material 3 Design

**State Management & Architecture:**
- `provider` (MVVM architecture binding)
- `go_router` (Advanced declarative routing, nested paths, and parameters)

**Media & UI:**
- `image_picker` (Video and gallery selection)
- `video_player` (Integrated video playback)
- `google_fonts` (Outfit typography family)
- `cupertino_icons` (iOS-style icon sets)

**Backend Integrations (Firebase):**
- `firebase_core` (Initialization)
- `firebase_auth` & `google_sign_in` (Authentication)
- `cloud_firestore` (Data persistence and logs)
- `firebase_storage` (Video hosting and asset endpoints)
- `firebase_analytics` & `firebase_crashlytics` (Telemetry and crash reporting)

**Utility & Monetization:**
- `http` (Network requests)
- `shared_preferences` (Local key-value storage)
- `in_app_purchase` & `razorpay_flutter` (Monetization gateways)
- `webview_flutter` & `url_launcher` (Web and external link handling)

**Backend Architecture (Python/FastAPI):**
- `fastapi` & `uvicorn` (Asynchronous HTTP server and SSE streaming endpoints)
- `groq` (High-speed LLM orchestration using Llama 3.3)
- `reportlab` (Server-side PDF generation)

---

## Clean Architecture (MVVM)

The project utilizes a feature-first clean folder structure separating concerns between data layers, business logic controllers, and views:

```text
lib/
├── core/
│   ├── navigation/        # GoRouter routes and redirect structures
│   ├── services/          # Global configurations and services
│   ├── theme/             # Palette gradients, shapes, and Material 3 theme configuration
│   └── widgets/           # Global reusable UI parts
│
└── features/
    ├── analysis/          # Dynamic scoring gauges and improvement items
    ├── auth/              # Account signups, Google log-ins, session caching
    ├── dashboard/         # Metrics counters and historic logs
    ├── hook_testing/      # Multi-concept A/B testing forms and winner cards
    ├── instagram/         # Instagram-specific optimization models
    ├── onboarding/        # Initial app walk-through and user setup
    ├── payments/          # Razorpay and In-App Purchase screens and logic
    ├── profile/           # User telemetry and settings
    ├── reel_upload/       # Picker triggers, upload progress, and previews
    └── reports/           # Detailed aggregated analytics output
```

---

## Backend Configurations

### Connecting a Live Firebase Backend:

1. **Create a project** in the Firebase console.
2. **Register apps** for both Android and iOS.
3. **Download Configuration Files**:
   - For Android: Place `google-services.json` inside the `android/app/` folder.
   - For iOS: Place `GoogleService-Info.plist` inside the `ios/Runner/` folder using Xcode.
4. **Enable Authentication Methods**: Email/Password and Google Sign-in.
5. **Setup Firestore**: Create a `reels` collection with appropriate read/write security rules.
6. **Setup Storage**: Allow reading and writing access to the `reels/` bucket.

### Running the FastAPI Microservice:

The AI Creator Copilot relies on a local FastAPI server for LLM orchestration and PDF generation.

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```
2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
3. **Set your environment variables:**
   Create a `.env` file containing your `GROQ_API_KEY`.
4. **Run the server:**
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

---

## Run and Compile Guidelines

To run locally on a connected emulator, simulator, or desktop target:

1. **Install Dependencies:**
   Fetch and configure all required packages:
   ```bash
   flutter pub get
   ```

2. **Code Quality Checks:**
   Check for linting, type errors, or warnings based on the predefined `analysis_options.yaml`:
   ```bash
   flutter analyze
   ```

3. **Run Application:**
   Compile and run the target build:
   ```bash
   flutter run
   ```
Can be used in ios as well as android with full seamless experience
