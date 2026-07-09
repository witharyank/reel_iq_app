import asyncio
import os
import json
from planner_engine import PlannerEngine
from pdf_generator import PDFGenerator

from dotenv import load_dotenv

load_dotenv()

async def run_test():
    engine = PlannerEngine(api_key=os.getenv("GROQ_API_KEY"))
    pdf_gen = PDFGenerator()
    
    # 1. Test Frequencies
    print("\n--- Testing Frequencies ---")
    freqs = ["Daily Reels", "2 Reels per day", "3 Reels per day"]
    for f in freqs:
        print(f"Testing {f}...")
        res = await engine.run_pipeline({"niche": "Tech", "audience": "Devs", "goal": "Views", "frequency": f, "durationDays": 7})
        total_days = len(res.get("days", []))
        print(f"Result for {f}: Generated {total_days} days. (Expected: {int(f[0]) * 7 if f[0].isdigit() else 7})")
        
    # 2. Test Niches
    print("\n--- Testing Niches ---")
    niches = [
        {"niche": "Personal Finance", "audience": "GenZ", "goal": "Build Trust"},
        {"niche": "Fitness Coaching", "audience": "Busy Moms", "goal": "Sell Course"},
        {"niche": "Travel Vlogging", "audience": "Solo Travelers", "goal": "Brand Deals"}
    ]
    
    for i, n in enumerate(niches):
        print(f"Testing Niche: {n['niche']}...")
        res = await engine.run_pipeline({"niche": n["niche"], "audience": n["audience"], "goal": n["goal"], "frequency": "3 Reels per week", "durationDays": 7})
        
        # Save JSON
        with open(f"qa_niche_{i}.json", "w") as f:
            json.dump(res, f, indent=2)
            
        # Generate PDF
        pdf_path = pdf_gen.generate_strategy_pdf(res)
        print(f"Generated PDF for {n['niche']}: {pdf_path}")
        print(f"Sample Hook: {res['days'][0]['hook']}")
        print(f"Sample Strategy: {res['weeks'][0]['weeklyStrategy']}")

if __name__ == "__main__":
    asyncio.run(run_test())
