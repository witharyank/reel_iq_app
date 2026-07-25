# ReelIQ - Project Architecture & Tech Stack

## 1. Overview
ReelIQ is a cross-platform application that uses AI to analyze short-form video content (Reels), evaluate creator profiles on Instagram, generate content reports, and help creators with their growth strategies.

## 2. App Architecture (Frontend)
- **Framework:** Flutter
- **Language:** Dart
- **Architecture Pattern:** Feature-first structure (inside `lib/features/`) separating the app into logical domains (`analysis`, `auth`, `dashboard`, `hook_testing`, `instagram`, `onboarding`, `payments`, `profile`, `reel_upload`, `reports`).
- **State Management:** `provider`
- **Routing:** `go_router`
- **Authentication & Database:** Firebase (Auth, Firestore, Storage)
- **Analytics & Crash Reporting:** Firebase Analytics, Firebase Crashlytics
- **In-App Payments:** `razorpay_flutter`, `in_app_purchase`
- **API Communication:** `http` package for making REST calls to the backend.

## 3. Backend Architecture
- **Framework:** FastAPI
- **Language:** Python
- **Server:** Uvicorn
- **AI Integration:** 
  - **Vision/Image Processing:** OpenCV (`opencv-python`) for frame extraction and scene change detection.
  - **OCR (Optical Character Recognition):** Tesseract (`pytesseract`) to extract text from video frames.
  - **Speech-to-Text:** OpenAI Whisper (local execution via `ffmpeg` audio extraction) to transcribe video audio.
  - **LLM/Generative AI:** Groq (Llama 3) via `ai_service.py` for generating insights, content calendars, and creator reports.
- **External APIs:**
  - **Instagram Graph API:** `instagram_service.py` handles authentication, profile analysis, and media fetching/scraping.
  - **Payment Gateway:** Razorpay (`payment_service.py`) for subscription handling and webhook verification.
- **Cloud Database Integration:** Firebase Admin SDK (Firestore) to update user data (e.g., subscription statuses) triggered by webhooks.

## 4. Backend Endpoints & Data Flow
The FastAPI backend exposes the following key endpoints:

### Video Analysis
- `POST /extract-frames`: Receives video upload, runs OpenCV and Tesseract for frame/text extraction, and uses Whisper for audio transcription.
- `POST /analyze-reel`: Combines extraction and AI analysis. Returns a full insights payload.
- `POST /analyze-url`: Downloads video from a URL, extracts data, and runs the AI model analysis.
- `POST /generate-insights`: Receives extracted metadata (scene changes, transcript, etc.) and asks the AI service for insights.

### Instagram Integration
- `GET /instagram/profile`: Fetches basic profile data using an Instagram access token.
- `GET /instagram/media`: Fetches the user's recent media (Videos/Reels).
- `POST /instagram/analyze-profile`: Uses the AI service to calculate statistics and analyze the provided profile data.
- `POST /instagram/public-profile-analysis`: Scrapes a public profile by username and analyzes the data.
- `POST /instagram/exchange-token`: Handles Instagram OAuth flow (exchanging code for short-lived and long-lived access tokens).

### AI Generation Tools
- `POST /generate-calendar`: Generates a 30-day content calendar based on niche, audience, and goals.
- `POST /generate-report`: Generates a weekly AI creator performance report with viral scores, hook strengths, and trend analysis using Groq.

### Payments
- `POST /payments/create-subscription`: Creates a Razorpay subscription for a user.
- `POST /payments/verify-subscription`: Verifies the Razorpay payment signature.
- `POST /payments/webhook`: Listens to Razorpay webhooks (e.g., `subscription.activated`) and updates the user's status directly in Firestore.

## 5. File & Directory Structure Summary
- `/lib/` - Flutter application code.
  - `/lib/core/` - Core app configurations, themes, constants.
  - `/lib/features/` - Modules organized by feature domain.
- `/backend/` - Python FastAPI application root.
  - `main.py` - FastAPI application configuration and endpoint routing.
  - `ai_service.py` - Handles communication with Groq LLM.
  - `instagram_service.py` - Interacts with Instagram Graph API.
  - `payment_service.py` - Manages Razorpay subscriptions and webhooks.
  - `/backend/temp_data/` - Temporary storage for video and audio files during processing.
