import asyncio
import os
import json
from dotenv import load_dotenv
from planner_engine import PlannerEngine

load_dotenv()

async def main():
    engine = PlannerEngine(api_key=os.getenv("GROQ_API_KEY"))
    
    req_data = {
        "niche": "Flutter Development",
        "audience": "Beginner Developers",
        "goal": "Get more newsletter subscribers",
        "frequency": "2 reels per week"
    }
    
    async def progress_cb(msg):
        print(f"[PROGRESS] {msg}")
        
    try:
        print("Starting PlannerEngine...")
        result = await engine.run_pipeline(req_data, progress_cb)
        print("\n\n=== RESULT ===")
        print(json.dumps(result, indent=2)[:1000] + "\n... (truncated)")
        
        # Test PDF Generation
        from pdf_generator import PDFGenerator
        pdf_gen = PDFGenerator()
        pdf_path = pdf_gen.generate_strategy_pdf(result)
        print(f"\nPDF generated at: {pdf_path}")
        
    except Exception as e:
        print(f"FAILED: {e}")

if __name__ == "__main__":
    asyncio.run(main())
