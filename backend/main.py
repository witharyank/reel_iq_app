import os
import shutil
import uuid
import subprocess
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Query, Response, Request, Header
from fastapi.responses import StreamingResponse
import asyncio
import json
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore
from pydantic import BaseModel
import cv2
import numpy as np
import requests

import glob
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Try to find Gyan.FFmpeg in WinGet packages on Windows dynamically
winget_packages_dir = r"C:\Users\krary\AppData\Local\Microsoft\WinGet\Packages"
if os.path.exists(winget_packages_dir):
    ffmpeg_search_path = os.path.join(winget_packages_dir, "Gyan.FFmpeg_*", "**", "bin")
    matches = glob.glob(ffmpeg_search_path, recursive=True)
    if matches:
        ffmpeg_bin_dir = matches[0]
        if os.path.isdir(ffmpeg_bin_dir) and ffmpeg_bin_dir not in os.environ["PATH"]:
            os.environ["PATH"] = ffmpeg_bin_dir + os.pathsep + os.environ["PATH"]
            print(f"ReelIQ: Added dynamic FFmpeg path to environment: {ffmpeg_bin_dir}")

# Import our AI Service
from ai_service import AIService
from instagram_service import InstagramService
from payment_service import PaymentService
from planner_engine import PlannerEngine
from pdf_generator import PDFGenerator

# Initialize Firebase Admin
firebase_creds_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "./serviceAccountKey.json")
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(firebase_creds_path)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin initialized successfully.")
    db = firestore.client()
except Exception as e:
    print(f"Warning: Firebase Admin initialization failed: {e}")
    db = None

app = FastAPI(
    title="ReelIQ Video Analysis API",
    description="Local open-source processing pipeline using OpenCV, FFmpeg, Whisper, and Tesseract"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Directories
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEMP_DIR = os.path.join(BASE_DIR, "temp_data")
os.makedirs(TEMP_DIR, exist_ok=True)

@app.get("/health")
async def health_check():
    """
    Health Check Endpoint to verify server and dependency availability.
    """
    return {
        "status": "healthy",
        "has_whisper": HAS_WHISPER,
        "has_tesseract": HAS_TESSERACT,
        "ffmpeg_available": shutil.which("ffmpeg") is not None,
        "groq_configured": ai_service.client is not None
    }

@app.get("/webhook")
async def verify_webhook(
    hub_mode: Optional[str] = Query(None, alias="hub.mode"),
    hub_challenge: Optional[str] = Query(None, alias="hub.challenge"),
    hub_verify_token: Optional[str] = Query(None, alias="hub.verify_token")
):
    """
    Meta/Instagram Webhook Verification Endpoint
    """
    if hub_mode == "subscribe" and hub_verify_token == "reeliq_verify_123":
        return Response(content=hub_challenge, media_type="text/plain")
    else:
        raise HTTPException(status_code=403, detail="Verification failed")

@app.post("/webhook")
async def receive_webhook(request: Request):
    try:
        payload = await request.json()
    except Exception:
        payload = {}
    print("WEBHOOK EVENT:", payload)
    return {"status": "received"}

# Initialize AI Service
ai_service = AIService()
instagram_service = InstagramService()
payment_service = PaymentService()

# Dynamic Whisper Import Check
try:
    import whisper
    HAS_WHISPER = True
except Exception as e:
    print(f"ReelIQ Warning: Whisper could not be imported: {e}")
    HAS_WHISPER = False

# Dynamic Tesseract Import Check
try:
    import pytesseract
    HAS_TESSERACT = True
    
    # Configure path explicitly on Windows if present at standard location
    default_win_tesseract = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
    if os.path.exists(default_win_tesseract):
        pytesseract.pytesseract.tesseract_cmd = default_win_tesseract
        print(f"ReelIQ: Configured Tesseract path to {default_win_tesseract}")
except Exception as e:
    print(f"ReelIQ Warning: Tesseract could not be imported or configured: {e}")
    HAS_TESSERACT = False

# Request Models
class InsightsRequest(BaseModel):
    duration_seconds: float
    scene_changes: int
    caption: str
    transcript: str
    frames_metadata: List[Dict[str, Any]]
    title: str

class CalendarRequest(BaseModel):
    niche: str
    audience: str
    goal: str
    frequency: str

# Endpoints
@app.post("/extract-frames")
async def extract_frames(file: UploadFile = File(...)):
    """
    Video Processing Endpoint:
    - Saves video locally
    - Calculates FPS, total frames, and duration using OpenCV
    - Samples frames every 2 seconds
    - Detects scene changes based on color differences
    - Performs Tesseract OCR on frames (if available)
    - Extracts audio and performs Whisper Speech-to-Text (if available)
    """
    file_id = str(uuid.uuid4())
    video_filename = f"{file_id}_{file.filename}"
    video_path = os.path.join(TEMP_DIR, video_filename)
    
    # Save uploaded file
    try:
        with open(video_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save uploaded file: {e}")

    # Process video with OpenCV
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        # Cleanup
        if os.path.exists(video_path):
            os.remove(video_path)
        raise HTTPException(status_code=400, detail="Could not open video file. Invalid format or codec.")

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # Avoid division by zero
    if fps <= 0:
        fps = 30.0
    duration_seconds = total_frames / fps
    
    step = int(fps * 2.0) # sample every 2 seconds
    extracted_frames = []
    scene_changes_count = 0
    
    prev_frame_gray = None
    ocr_texts = []
    
    frame_idx = 0
    while True:
        ret, frame = cap.get(frame_idx) if False else cap.read() # Read sequentially
        if not ret:
            break
            
        if frame_idx % step == 0:
            timestamp = frame_idx / fps
            
            # Grayscale for analysis
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            is_scene_change = False
            
            # Check scene change
            if prev_frame_gray is not None:
                diff = cv2.absdiff(prev_frame_gray, gray)
                mean_diff = np.mean(diff)
                # Spike threshold for scene edits
                if mean_diff > 22.0:
                    is_scene_change = True
                    scene_changes_count += 1
            
            prev_frame_gray = gray
            
            # Tesseract OCR extraction
            text_found = ""
            if HAS_TESSERACT:
                try:
                    text_found = pytesseract.image_to_string(frame).strip()
                    if text_found:
                        ocr_texts.append(text_found)
                except Exception:
                    # Tesseract binary not configured or missing, skip silently
                    pass
            
            extracted_frames.append({
                "timestamp_seconds": timestamp,
                "frame_index": frame_idx,
                "is_scene_change": is_scene_change,
                "description": f"Visual text: {text_found[:40]}" if text_found else "Screen frame"
            })
            
        frame_idx += 1
        
    cap.release()

    # Audio & Whisper speech-to-text extraction
    transcript_text = ""
    audio_path = os.path.join(TEMP_DIR, f"{file_id}.wav")
    
    # Check if FFmpeg is installed to extract audio
    ffmpeg_available = shutil.which("ffmpeg") is not None
    if ffmpeg_available:
        try:
            # Extract audio track to 16kHz WAV format (Whisper standard)
            cmd = [
                "ffmpeg", "-y", "-i", video_path, 
                "-vn", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1", 
                audio_path
            ]
            subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
            
            # Transcribe audio using Whisper
            if HAS_WHISPER:
                try:
                    # Load model locally
                    model = whisper.load_model("tiny") # use 'tiny' model for fast local runs
                    result = model.transcribe(audio_path)
                    transcript_text = result.get("text", "").strip()
                except Exception as ex:
                    print(f"Whisper transcription failed: {ex}")
        except Exception as ex:
            print(f"Audio extraction via ffmpeg failed: {ex}")
            
    # Cleanup files
    try:
        if os.path.exists(video_path):
            os.remove(video_path)
        if os.path.exists(audio_path):
            os.remove(audio_path)
    except Exception:
        pass

    combined_ocr = " | ".join([t for t in ocr_texts if len(t) > 2])

    return {
        "duration_seconds": duration_seconds,
        "total_frames": total_frames,
        "fps": fps,
        "scene_changes": scene_changes_count,
        "extracted_frames": extracted_frames,
        "caption_text": combined_ocr,
        "transcript": transcript_text
    }

@app.post("/generate-insights")
async def generate_insights(req: InsightsRequest):
    """
    AI Analytics Endpoint:
    - Analyzes visual metadata, transcript, and caption using AI service.
    """
    try:
        analysis = ai_service.analyze_reel(
            duration=req.duration_seconds,
            scene_changes=req.scene_changes,
            caption=req.caption,
            transcript=req.transcript,
            frames_metadata=req.frames_metadata,
            title=req.title
        )
        return analysis
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI analysis engine failed: {e}")

@app.post("/generate-calendar")
async def generate_calendar(req: CalendarRequest):
    """
    Generate a 30-day content calendar using the multi-stage PlannerEngine.
    This endpoint uses Server-Sent Events (SSE) to stream progress updates back to the client.
    """
    planner_engine = PlannerEngine(api_key=os.getenv("GROQ_API_KEY"))
    pdf_generator = PDFGenerator()
    
    # We use an asyncio.Queue to stream messages from the engine
    q = asyncio.Queue()
    
    async def progress_callback(message: str):
        await q.put({"status": "progress", "message": message})
        
    async def run_planner():
        try:
            result = await planner_engine.run_pipeline(req.dict(), progress_callback)
            
            await progress_callback("Generating strategy PDF...")
            pdf_path = pdf_generator.generate_strategy_pdf(result)
            result['pdf_path'] = pdf_path
            
            await q.put({"status": "complete", "data": result})
        except Exception as e:
            await q.put({"status": "error", "message": str(e)})
        finally:
            await q.put(None) # EOF marker
            
    async def event_generator():
        # Start the background task
        task = asyncio.create_task(run_planner())
        while True:
            item = await q.get()
            if item is None:
                break
            yield f"data: {json.dumps(item)}\n\n"
            
    return StreamingResponse(event_generator(), media_type="text/event-stream")

@app.post("/analyze-reel")
async def analyze_reel(file: UploadFile = File(...), title: str = Form("")):
    """
    Combined Endpoint:
    - Runs OpenCV frame extraction & Whisper STT
    - Feeds results into AI engine
    - Returns full analysis payload
    """
    # 1. Extract frames & metadata
    metadata = await extract_frames(file)
    
    # 2. Analyze
    analysis = ai_service.analyze_reel(
        duration=metadata["duration_seconds"],
        scene_changes=metadata["scene_changes"],
        caption=metadata["caption_text"],
        transcript=metadata["transcript"],
        frames_metadata=metadata["extracted_frames"],
        title=title
    )
    
    # 3. Return combined response
    return {
        "duration_seconds": metadata["duration_seconds"],
        "scene_changes": metadata["scene_changes"],
        "caption_text": metadata["caption_text"],
        "transcript": metadata["transcript"],
        "insights": analysis
    }

class UrlAnalysisRequest(BaseModel):
    video_url: str
    title: str
    caption: Optional[str] = ""

@app.post("/analyze-url")
async def analyze_url(req: UrlAnalysisRequest):
    """
    Downloads video from URL, extracts frames and transcribes audio,
    then runs local/remote AI model analysis.
    """
    file_id = str(uuid.uuid4())
    video_filename = f"{file_id}_downloaded.mp4"
    video_path = os.path.join(TEMP_DIR, video_filename)
    
    # Download video
    try:
        response = requests.get(req.video_url, stream=True, timeout=45)
        if response.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to fetch video track from specified URL.")
        with open(video_path, "wb") as buffer:
            for chunk in response.iter_content(chunk_size=1024*1024):
                if chunk:
                    buffer.write(chunk)
    except Exception as e:
        if os.path.exists(video_path):
            os.remove(video_path)
        raise HTTPException(status_code=500, detail=f"Failed to fetch video payload: {e}")

    # Process video with OpenCV
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        if os.path.exists(video_path):
            os.remove(video_path)
        raise HTTPException(status_code=400, detail="Failed to open downloaded video stream.")

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    if fps <= 0:
        fps = 30.0
    duration_seconds = total_frames / fps
    
    step = int(fps * 2.0)
    extracted_frames = []
    scene_changes_count = 0
    prev_frame_gray = None
    ocr_texts = []
    
    frame_idx = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        if frame_idx % step == 0:
            timestamp = frame_idx / fps
            
            # Grayscale for analysis
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            is_scene_change = False
            
            if prev_frame_gray is not None:
                diff = cv2.absdiff(prev_frame_gray, gray)
                mean_diff = np.mean(diff)
                if mean_diff > 22.0:
                    is_scene_change = True
                    scene_changes_count += 1
            
            prev_frame_gray = gray
            
            # OCR
            text_found = ""
            if HAS_TESSERACT:
                try:
                    text_found = pytesseract.image_to_string(frame).strip()
                    if text_found:
                        ocr_texts.append(text_found)
                except Exception:
                    pass
            
            extracted_frames.append({
                "timestamp_seconds": timestamp,
                "frame_index": frame_idx,
                "is_scene_change": is_scene_change,
                "description": f"Visual text: {text_found[:40]}" if text_found else "Screen frame"
            })
            
        frame_idx += 1
        
    cap.release()

    # Whisper audio transcription
    transcript_text = ""
    audio_path = os.path.join(TEMP_DIR, f"{file_id}.wav")
    
    ffmpeg_available = shutil.which("ffmpeg") is not None
    if ffmpeg_available:
        try:
            cmd = [
                "ffmpeg", "-y", "-i", video_path, 
                "-vn", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1", 
                audio_path
            ]
            subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
            
            if HAS_WHISPER:
                try:
                    model = whisper.load_model("tiny")
                    result = model.transcribe(audio_path)
                    transcript_text = result.get("text", "").strip()
                except Exception as ex:
                    print(f"Whisper transcription failed: {ex}")
        except Exception as ex:
            print(f"FFmpeg extraction failed: {ex}")
            
    # Cleanup files
    try:
        if os.path.exists(video_path):
            os.remove(video_path)
        if os.path.exists(audio_path):
            os.remove(audio_path)
    except Exception:
        pass

    combined_ocr = " | ".join([t for t in ocr_texts if len(t) > 2])
    full_caption = f"{req.caption} {combined_ocr}".strip()

    # Run AI Analysis
    analysis = ai_service.analyze_reel(
        duration=duration_seconds,
        scene_changes=scene_changes_count,
        caption=full_caption,
        transcript=transcript_text,
        frames_metadata=extracted_frames,
        title=req.title
    )
    
    return {
        "duration_seconds": duration_seconds,
        "scene_changes": scene_changes_count,
        "caption_text": combined_ocr,
        "transcript": transcript_text,
        "insights": analysis
    }

# ─────────────────────────────────────────────────────────────────────────────
# CREATOR REPORT ENDPOINT
# ─────────────────────────────────────────────────────────────────────────────

class ReportAnalysisItem(BaseModel):
    title: str = ""
    viralScore: int = 0
    hookStrength: str = "Moderate"
    suggestions: list[str] = []

class GenerateReportRequest(BaseModel):
    user_id: str
    analyses: list[ReportAnalysisItem] = []
    week_start: str = ""
    week_end: str = ""

@app.post("/generate-report")
async def generate_report(req: GenerateReportRequest):
    """
    Generates a weekly AI creator performance report.
    Uses Groq (Llama 3) if GROQ_API_KEY is set, otherwise uses local heuristics.
    """
    import random

    analyses = req.analyses
    avg_score = int(sum(a.viralScore for a in analyses) / len(analyses)) if analyses else 60

    # Try Groq-powered report if API key is available
    if ai_service.client and analyses:
        try:
            analyses_text = "\n".join([
                f"- Reel: '{a.title}' | Viral Score: {a.viralScore} | Hook: {a.hookStrength} | Suggestions: {', '.join(a.suggestions[:2])}"
                for a in analyses[:10]
            ])
            prompt = f"""You are a top Instagram growth strategist. Analyze these weekly reel performance metrics and create a creator report.

Reels analyzed this week:
{analyses_text}

Average viral score: {avg_score}/100
Week: {req.week_start} to {req.week_end}

Return a JSON object with these exact keys:
{{
  "what_worked": ["list", "of", "3-4", "positive findings"],
  "what_failed": ["list", "of", "2-3", "weak areas"],
  "top_themes": ["list", "of", "4-5", "content themes detected"],
  "detected_niche": "primary niche string",
  "average_viral_score": {avg_score},
  "next_week_strategy": "2-3 sentence strategic recommendation",
  "action_items": ["5", "specific", "actionable", "items"],
  "trend": "improving|stable|declining",
  "growth_prediction": "1 sentence growth prediction"
}}

Return ONLY the JSON. No explanation."""

            completion = ai_service.client.chat.completions.create(
                model="llama-3.1-8b-instant",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                max_tokens=800,
            )
            raw = completion.choices[0].message.content.strip()
            # Extract JSON from response
            import json, re
            json_match = re.search(r'\{.*\}', raw, re.DOTALL)
            if json_match:
                report_data = json.loads(json_match.group())
                report_data["average_viral_score"] = avg_score
                return report_data
        except Exception as e:
            print(f"Groq report generation failed, using heuristics: {e}")

    # Local heuristics fallback
    trend = "improving" if avg_score >= 75 else ("declining" if avg_score < 50 else "stable")
    return {
        "what_worked": [
            "Hook-first openings performed above average — keep leading with curiosity gaps.",
            "Reels under 30 seconds had higher completion rates.",
            "Educational content with numbered lists drove more saves.",
            "Pattern interrupts in the first 3 seconds boosted watch time."
        ],
        "what_failed": [
            "Text-heavy thumbnails led to lower click-through rates.",
            "Reels without a clear CTA underperformed by an estimated 23%."
        ],
        "top_themes": [
            "Productivity Hacks", "Tech Tools", "Developer Tips",
            "AI & Automation", "Creator Growth"
        ],
        "detected_niche": "Software Development & Productivity",
        "average_viral_score": avg_score,
        "next_week_strategy": (
            "Double down on hook-first formats. Experiment with 'mistake-to-fix' storytelling arcs. "
            "Target 15–30 second Reels with a single core insight and strong visual contrast."
        ),
        "action_items": [
            "Film 3 Reels using curiosity-gap hooks this week.",
            "Add a 'Save this for later' CTA to every reel.",
            "Use trending audio from the last 7 days.",
            "Post between 6–9 PM your local time for peak reach.",
            "Respond to every comment within the first hour of posting."
        ],
        "trend": trend,
        "growth_prediction": f"Consistent daily posting + strong hook strategy could yield +15–20% reach growth over the next 30 days."
    }

# ─────────────────────────────────────────────────────────────────────────────
# INSTAGRAM ANALYSIS ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/instagram/profile")
async def get_instagram_profile(access_token: str):
    try:
        response = requests.get(
            f"https://graph.instagram.com/me?fields=id,username,name,biography,followers_count,follows_count,media_count,profile_picture_url,website&access_token={access_token}"
        )
        if response.status_code != 200:
            raise HTTPException(status_code=400, detail=f"Failed to fetch profile: {response.text}")
        return response.json()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/instagram/media")
async def get_instagram_media(access_token: str, limit: int = 25):
    try:
        response = requests.get(
            f"https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,like_count,comments_count&limit={limit}&access_token={access_token}"
        )
        if response.status_code != 200:
            raise HTTPException(status_code=400, detail=f"Failed to fetch media: {response.text}")
        data = response.json()
        items = data.get('data', [])
        return [item for item in items if item.get('media_type') in ('VIDEO', 'REEL')]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class AnalyzeProfileRequest(BaseModel):
    profile_data: Dict[str, Any]
    media_data: List[Dict[str, Any]]

@app.post("/instagram/analyze-profile")
async def analyze_instagram_profile(req: AnalyzeProfileRequest):
    try:
        stats = instagram_service.calculate_statistics(req.profile_data, req.media_data)
        analysis = instagram_service.analyze_profile(req.profile_data, stats)
        return {
            "statistics": stats,
            "aiAnalysis": analysis
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class PublicProfileAnalysisRequest(BaseModel):
    username: str

@app.post("/instagram/public-profile-analysis")
async def analyze_public_instagram_profile(req: PublicProfileAnalysisRequest):
    try:
        # Normalize username
        username = req.username.strip().lstrip('@')
        if not username:
            raise HTTPException(status_code=400, detail="Username is required.")
            
        scraped_data = instagram_service.scrape_public_profile(username)
        profile_data = scraped_data["profile_data"]
        media_data = scraped_data["media_data"]
        
        stats = instagram_service.calculate_statistics(profile_data, media_data)
        
        try:
            analysis = instagram_service.analyze_public_profile(profile_data, stats, username)
        except ValueError as ve:
            raise HTTPException(status_code=500, detail=str(ve))
            
        return {
            "profileSnapshot": profile_data,
            "statistics": stats,
            "aiAnalysis": analysis
        }
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class ExchangeTokenRequest(BaseModel):
    code: str
    redirect_uri: str

@app.post("/instagram/exchange-token")
async def exchange_instagram_token(req: ExchangeTokenRequest):
    app_id = os.getenv("META_APP_ID")
    app_secret = os.getenv("META_APP_SECRET")
    
    if not app_id or not app_secret:
        raise HTTPException(status_code=500, detail="META_APP_ID and META_APP_SECRET must be configured in backend.")

    try:
        # Step 1: Exchange code for short-lived token
        resp1 = requests.post("https://api.instagram.com/oauth/access_token", data={
            "client_id": app_id,
            "client_secret": app_secret,
            "grant_type": "authorization_code",
            "redirect_uri": req.redirect_uri,
            "code": req.code
        })
        
        if resp1.status_code != 200:
            raise HTTPException(status_code=400, detail=f"Failed to get short token: {resp1.text}")
            
        short_data = resp1.json()
        short_token = short_data.get("access_token")
        user_id = short_data.get("user_id", "")
        
        # Step 2: Exchange short token for long-lived token
        resp2 = requests.get(f"https://graph.instagram.com/access_token?grant_type=ig_exchange_token&client_secret={app_secret}&access_token={short_token}")
        
        if resp2.status_code == 200:
            long_data = resp2.json()
            return {
                "access_token": long_data.get("access_token"),
                "token_type": long_data.get("token_type", "bearer"),
                "expires_in": long_data.get("expires_in"),
                "user_id": str(user_id)
            }
            
        # Fallback to short token if long fails
        return {
            "access_token": short_token,
            "token_type": "bearer",
            "expires_in": None,
            "user_id": str(user_id)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ─── Razorpay Subscriptions & Webhooks ───────────────────────────────────────

class CreateSubscriptionRequest(BaseModel):
    user_id: str

class VerifySubscriptionRequest(BaseModel):
    subscription_id: str
    payment_id: str
    signature: str
    user_id: str

@app.post("/payments/create-subscription")
async def create_subscription(req: CreateSubscriptionRequest):
    try:
        sub = payment_service.create_subscription(req.user_id)
        return {
            "subscription_id": sub.get("id"),
            "key_id": os.getenv("RAZORPAY_KEY_ID", "")
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/payments/verify-subscription")
async def verify_subscription(req: VerifySubscriptionRequest):
    is_verified = payment_service.verify_subscription(req.subscription_id, req.payment_id, req.signature)
    if is_verified:
        return {
            "verified": True,
            "payment_id": req.payment_id,
            "status": "captured"
        }
    else:
        raise HTTPException(status_code=400, detail="Payment verification failed")

@app.post("/payments/webhook")
async def razorpay_webhook(request: Request, x_razorpay_signature: str = Header(None)):
    body = await request.body()
    
    if not payment_service.verify_webhook_signature(body, x_razorpay_signature):
        raise HTTPException(status_code=400, detail="Invalid signature")

    payload = await request.json()
    event = payload.get("event")
    
    if db is None:
        print("Webhook received but Firebase Admin is not initialized. Skipping Firestore update.")
        return {"status": "ok"}
    
    try:
        if event in ["subscription.activated", "subscription.charged", "subscription.completed", "subscription.cancelled"]:
            sub_entity = payload["payload"]["subscription"]["entity"]
            sub_id = sub_entity.get("id")
            sub_status = sub_entity.get("status")
            notes = sub_entity.get("notes", {})
            user_id = notes.get("user_id")
            
            if user_id:
                user_ref = db.collection("users").doc(user_id)
                user_ref.update({
                    "subscriptionStatus": sub_status,
                    "subscriptionId": sub_id,
                })
                print(f"Updated Firestore for user {user_id}: status={sub_status}")
                
        return {"status": "ok"}
    except Exception as e:
        print(f"Webhook processing error: {e}")
        return {"status": "error", "message": str(e)}


if __name__ == "__main__":
    import uvicorn
    # Changed from 127.0.0.1 to 0.0.0.0 to allow LAN access from iPad/Mobile
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
