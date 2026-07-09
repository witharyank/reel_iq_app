import json
import asyncio
from typing import Dict, Any, List, Optional
import os
from groq import AsyncGroq
import re

class PlannerEngine:
    def __init__(self, api_key: str):
        self.client = AsyncGroq(api_key=api_key) if api_key else None
        self.model = "llama-3.3-70b-versatile"
    
    def parse_frequency(self, frequency: str) -> dict:
        """Parses frequency strings like '3 Reels per week' into total days and posts per day/week."""
        frequency = frequency.lower()
        if "daily" in frequency:
            return {"posts_per_week": 7, "total_posts": 30, "weeks": 4}
        
        match = re.search(r'(\d+)\s*reels?\s*per\s*week', frequency)
        if match:
            per_week = int(match.group(1))
            return {"posts_per_week": per_week, "total_posts": per_week * 4, "weeks": 4}
            
        return {"posts_per_week": 3, "total_posts": 12, "weeks": 4} # Default fallback

    async def _call_llm(self, system_prompt: str, user_prompt: str, max_retries: int = 3) -> dict:
        if not self.client:
            raise Exception("Groq API Key missing. Cannot run planner engine.")
            
        for attempt in range(max_retries):
            try:
                chat_completion = await self.client.chat.completions.create(
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt}
                    ],
                    model=self.model,
                    temperature=0.7,
                    response_format={"type": "json_object"}
                )
                content = chat_completion.choices[0].message.content
                return json.loads(content)
            except json.JSONDecodeError as e:
                print(f"JSON Parse Error on attempt {attempt + 1}: {e}")
                if attempt == max_retries - 1:
                    raise Exception(f"Failed to generate valid JSON after {max_retries} attempts.")
            except Exception as e:
                print(f"LLM Call Failed on attempt {attempt + 1}: {e}")
                if attempt == max_retries - 1:
                    raise e
        return {}

    async def generate_stage_1_strategy(self, niche: str, audience: str, goal: str) -> dict:
        system_prompt = (
            "You are a top-tier Senior Marketing Strategist. Generate a monthly strategy and content gap analysis in JSON.\n"
            "Schema:\n"
            "{\n"
            "  \"monthlyGoal\": \"string\",\n"
            "  \"monthlyKPIs\": [\"string\"],\n"
            "  \"contentGapAnalysis\": {\n"
            "    \"missingInNiche\": \"string\",\n"
            "    \"opportunity\": \"string\",\n"
            "    \"competitorWeakness\": \"string\"\n"
            "  },\n"
            "  \"contentMixBreakdown\": {\"educational\": 0, \"entertaining\": 0, \"promotional\": 0},\n"
            "  \"platformDistribution\": {\"instagram\": 100}\n"
            "}"
        )
        user_prompt = f"Create a bold, non-generic strategy for a creator in the '{niche}' niche targeting '{audience}' with the goal of '{goal}'."
        return await self._call_llm(system_prompt, user_prompt)

    async def generate_stage_2_weekly_plans(self, niche: str, audience: str, goal: str, strategy: dict, total_weeks: int) -> dict:
        system_prompt = (
            f"You are a Senior Marketing Strategist. Generate a highly detailed plan for {total_weeks} weeks. Output JSON.\n"
            "The month must feel like one connected campaign.\n"
            "Schema: {\"weeks\": [ { \"weekNumber\": int, \"weeklyGoal\": \"string\", \"weeklyKPIs\": [\"string\"], \"weeklyStrategy\": \"string\", \"growthCoach\": { \"improve\": \"string\", \"stop\": \"string\", \"trendSuggestion\": \"string\" } } ] }"
        )
        user_prompt = f"Niche: {niche}\nAudience: {audience}\nGoal: {goal}\nMonthly Strategy: {json.dumps(strategy)}\nCreate the weekly progression."
        return await self._call_llm(system_prompt, user_prompt)

    async def generate_stage_3_4_5_content(self, niche: str, audience: str, goal: str, week_plan: dict, posts_this_week: int, previous_context: str = "") -> dict:
        system_prompt = (
            f"You are a Master Copywriter and Psychologist. Generate {posts_this_week} highly detailed, viral social media posts for this week in JSON format.\n"
            "CRITICAL RULES:\n"
            "1. NEVER duplicate hooks, captions, or CTAs.\n"
            "2. Ensure each piece of content has a unique psychology principle and specific reasoning.\n"
            "3. Do NOT use generic ChatGPT formats. Be extremely specific and highly creative.\n"
            "4. Ensure natural progression throughout the week.\n"
            "Schema:\n"
            "{\n"
            "  \"days\": [\n"
            "    {\n"
            "      \"title\": \"String\",\n"
            "      \"dailyObjective\": \"String\",\n"
            "      \"funnelStage\": \"Top/Middle/Bottom\",\n"
            "      \"contentPillar\": \"String\",\n"
            "      \"contentFormat\": \"Reel/Carousel/Story/Single Image\",\n"
            "      \"platform\": \"String\",\n"
            "      \"targetAudience\": \"String\",\n"
            "      \"psychologyUsed\": \"String\",\n"
            "      \"whyThisWorks\": \"String\",\n"
            "      \"emotionTriggered\": \"String\",\n"
            "      \"hook\": \"String\",\n"
            "      \"alternativeHooks\": [\"String\"],\n"
            "      \"fullScript\": \"String\",\n"
            "      \"bRollSuggestions\": \"String\",\n"
            "      \"cameraAngles\": \"String\",\n"
            "      \"shotList\": \"String\",\n"
            "      \"textOverlayTimeline\": \"String\",\n"
            "      \"editingInstructions\": \"String\",\n"
            "      \"musicSuggestions\": \"String\",\n"
            "      \"caption\": \"String\",\n"
            "      \"alternativeCaptions\": [\"String\"],\n"
            "      \"cta\": \"String\",\n"
            "      \"alternativeCTAs\": [\"String\"],\n"
            "      \"hashtags\": \"String\",\n"
            "      \"thumbnailIdea\": \"String\",\n"
            "      \"thumbnailText\": \"String\",\n"
            "      \"postingTime\": \"String\",\n"
            "      \"difficulty\": \"Easy/Medium/Hard\",\n"
            "      \"estimatedCreationTime\": \"String\",\n"
            "      \"expectedEngagement\": \"String\",\n"
            "      \"reachEstimate\": \"String\",\n"
            "      \"viralityPotential\": 85,\n"
            "      \"preProductionChecklist\": [\"String\"],\n"
            "      \"shootChecklist\": [\"String\"],\n"
            "      \"editChecklist\": [\"String\"],\n"
            "      \"uploadChecklist\": [\"String\"]\n"
            "    }\n"
            "  ]\n"
            "}\n"
        )
        
        memory_instruction = f"Previously generated ideas to AVOID repeating: {previous_context}\n" if previous_context else ""
        
        user_prompt = (
            f"Niche: {niche}\n"
            f"Audience: {audience}\n"
            f"Goal: {goal}\n"
            f"Weekly Plan: {json.dumps(week_plan)}\n\n"
            f"{memory_instruction}"
            f"Generate exact JSON matching the schema for {posts_this_week} posts."
        )
        return await self._call_llm(system_prompt, user_prompt)

    async def run_pipeline(self, request_data: dict, progress_callback=None) -> dict:
        niche = request_data.get("niche", "")
        audience = request_data.get("audience", "")
        goal = request_data.get("goal", "")
        frequency_str = request_data.get("frequency", "")
        duration_days = request_data.get("durationDays", 30)
        
        freq_calc = self.parse_frequency(frequency_str)
        posts_per_week = freq_calc["posts_per_week"]
        total_weeks = max(1, duration_days // 7)
        total_posts = posts_per_week * total_weeks
        
        if progress_callback:
            await progress_callback("Analyzing your niche and competitors...")
            
        strategy = await self.generate_stage_1_strategy(niche, audience, goal)
        
        if progress_callback:
            await progress_callback(f"Building campaign strategies for {total_weeks} weeks...")
            
        weekly_plans_res = await self.generate_stage_2_weekly_plans(niche, audience, goal, strategy, total_weeks)
        weekly_plans = weekly_plans_res.get("weeks", [])
        
        all_days = []
        
        if progress_callback:
            await progress_callback("Generating daily content, hooks, and psychology (running sequentially to maintain AI memory)...")
            
        day_counter = 1
        previous_context = ""
        
        for idx, week in enumerate(weekly_plans):
            if progress_callback:
                await progress_callback(f"Generating content for Week {idx + 1}...")
                
            week_content = await self.generate_stage_3_4_5_content(niche, audience, goal, week, posts_per_week, previous_context)
            
            for item in week_content.get("days", []):
                item["day"] = day_counter
                item["weekNumber"] = idx + 1
                item["bestPostingTime"] = "12:00 PM"
                item["difficulty"] = "Medium"
                item["estimatedCreationTime"] = "45 mins"
                item["expectedEngagement"] = "High"
                item["reachEstimate"] = "10k-50k"
                item["confidenceScore"] = item.get("viralityPotential", 85)
                item["roiEstimate"] = "Brand Awareness"
                
                item["preProductionChecklist"] = ["Write script", "Gather props"]
                item["shootChecklist"] = ["Check lighting", "Record A-roll"]
                item["editChecklist"] = ["Cut dead air", "Add captions"]
                item["uploadChecklist"] = ["Write caption", "Add tags"]
                item["repurposeSuggestions"] = "Post to TikTok and YouTube Shorts"
                item["successMetrics"] = "Views, Shares, Saves"
                
                # Make sure the old keys exist to not break existing models immediately
                item["idea"] = item.get("fullScript", "")
                
                all_days.append(item)
                day_counter += 1

        if progress_callback:
            await progress_callback("Finalizing your strategy deck...")
            
        result = {
            "id": f"cal_{day_counter}",
            "monthlyGoal": strategy.get("monthlyGoal", goal),
            "monthlyKPIs": strategy.get("monthlyKPIs", []),
            "contentGapAnalysis": strategy.get("contentGapAnalysis", {}),
            "contentMixBreakdown": strategy.get("contentMixBreakdown", {}),
            "platformDistribution": strategy.get("platformDistribution", {}),
            "niche": niche,
            "audience": audience,
            "goal": goal,
            "frequency": frequency_str,
            "weeks": weekly_plans,
            "days": all_days
        }
        
        return result
