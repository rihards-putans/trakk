"""Trakk Dashboard Coach adapter for quality-loop. Mirrors DashboardViewModel.buildInsightPrompt exactly."""
from quality_loop.adapter import PipelineAdapter
from quality_loop.llm import call_model


def _build_user_content(e: dict) -> str:
    clock = e["clock_time"]
    hour = int(clock.split(":")[0])
    if 5 <= hour < 12:
        time_context = "morning — most of the day still ahead for eating"
        late_night = ""
    elif 12 <= hour < 15:
        time_context = "early afternoon — roughly halfway through the day"
        late_night = ""
    elif 15 <= hour < 18:
        time_context = "late afternoon — main evening meal still ahead"
        late_night = ""
    elif 18 <= hour < 22:
        time_context = "evening — winding down, last meal of the day window"
        late_night = ""
    else:
        time_context = "late night / past midnight — the user is heading to bed soon (or already asleep)"
        late_night = (
            "\n\n                CRITICAL: Do NOT suggest eating anything (no dinner, snacks, "
            "protein shakes — nothing). The user is going to sleep within the next ~hour. "
            "If the calorie count looks low, remember the day just rolled over at midnight — "
            "that 0 kcal does not mean the user under-ate yesterday, it means today just started. "
            "Focus on hydration, sleep quality, recovery, or a one-line plan for tomorrow."
        )

    remaining = max(0, e["calorieTarget"] - e["todayEaten"])
    return (
        "Give me a 2-sentence coaching tip based on my current status:\n"
        f"- Current clock time: {clock}\n"
        f"- Time of day: {time_context}\n"
        f"- Workout: {e['workout']}\n"
        f"- Current weight: {e['currentWeight']} kg\n"
        f"- Goal weight: {int(e['goalWeight'])} kg\n"
        f"- Calories eaten today: {int(e['todayEaten'])} of {int(e['calorieTarget'])} target ({int(remaining)} remaining)\n"
        f"- Protein: {int(e['todayProtein'])}g of {int(e['proteinTarget'])}g target\n"
        f"- Streak: {e['streak']} days on track\n"
        f"- Calories burned today (active only): {int(e['todayBurned'])} kcal\n"
        "Consider the time of day — a large remaining budget in the morning is normal, not alarming."
        f"{late_night}\n"
        "Be specific, concise, and encouraging."
    )


class TrakkDashboardCoachAdapter(PipelineAdapter):
    pipeline_name = "trakk-dashboard-coach"
    target_model = "claude-haiku-4-5-20251001"

    def run(self, prompt_template: str, eval_input: dict) -> str:
        user_content = _build_user_content(eval_input["inputs"])
        return call_model(
            messages=[{"role": "user", "content": user_content}],
            system=prompt_template,
            model=self.target_model,
            max_tokens=200,
            temperature=0.7,
        )
