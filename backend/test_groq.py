import sys
import os

# Add the backend directory to sys.path so we can import ai_service
backend_dir = r"c:\Users\krary\OneDrive\Desktop\Reels_iqq\backend"
sys.path.append(backend_dir)
os.chdir(backend_dir)

from dotenv import load_dotenv
load_dotenv()

try:
    from ai_service import AIService
except ImportError as e:
    print(f"Failed to import AIService: {e}")
    sys.exit(1)

def test_groq():
    service = AIService()
    
    if not service.client:
        print("FAIL: Groq API client is not initialized in AIService. Check API key.")
        sys.exit(1)
        
    print(f"Testing Groq Calendar Generation with API Key: {service.api_key[:5]}...")
    
    try:
        calendar = service.generate_content_calendar(
            niche="Software Engineering",
            audience="Beginner Programmers",
            goal="Engagement",
            frequency="Daily"
        )
        print("\n=== GENERATED CALENDAR ===")
        import json
        print(json.dumps(calendar, indent=2))
        print("=== END CALENDAR ===")
        print("SUCCESS: Groq Calendar generation works.")
    except Exception as e:
        print(f"FAIL: Groq API generated an exception: {e}")

if __name__ == "__main__":
    test_groq()
