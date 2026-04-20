# Trakk

A native iOS weight-loss companion that unifies Apple Health, barcode scanning, and an AI coach. Built for my own daily use during a cut from 78.9 kg toward a 70–72 kg target.

## Why this exists

My protocol required me to check three separate apps every day — HealthKit for weight and workouts, a food tracker for macros, and a chatbot for questions about what to eat. Nothing unified them. I'd never written iOS code before. Built anyway.

## What's interesting technically

- **Agentic tool-use loop for the coach.** Instead of parsing JSON from free text (brittle — early versions dropped items and silently replaced them), the Claude API surface exposes six tools (`add_food_items`, `modify_pending_item`, `remove_pending_item`, `clear_pending_items`, `get_food_log`, `get_weight_history`). Code owns the state transitions; the model only chooses which mutation to call. Agentic loop runs up to 5 iterations per user turn. Both earlier failure modes became structurally impossible.
- **Time-aware dashboard coach.** Injects wall-clock time and workout context into every insight prompt with an inline `CRITICAL: Do NOT suggest eating between 22:00–05:00` directive. Without it, Claude reliably recommends midnight meals. With it, zero false positives over weeks of use.
- **Custom barcode cache.** Open Food Facts has gaps for Baltic products. Lookup falls back to a per-barcode Core Data cache — scan once, save per-100g values, every subsequent scan is local and offline.
- **Quality-loop integration.** The dashboard-coach prompt is bundled from a shared source file that also powers an eval harness (`evals/dashboard-coach/`). A SHA256 invariant on both the Python source and the built `.app` bundle asserts they run byte-identical prompts. If the hashes diverge, something is wrong.
- **Passive labeling pipeline.** Each generated insight is logged as JSONL with outcome tracking (accepted / dismissed / regenerated / ignored), hooked into the single Core Data persistence funnel (`createFoodEntry`). No duplicate hooks, no double-counting.
- **Core Data migration clamp-on-read.** Lightweight migrations set new attributes to 0/null rather than `defaultValue` — that fires only on `Entity(context:)` for new rows. So every new attribute gets a clamp-on-read with write-back repair.

## Stack

SwiftUI · MVVM · Core Data (programmatic, lightweight migration) · HealthKit · VisionKit (barcode) · Claude API (Haiku + tool-use) · Open Food Facts · Swift 6 strict concurrency · ocean teal dark palette

## Status

Personal daily driver since April 2026. 49 Swift files. Deployed to iPhone 14 Pro Max via free provisioning and `xcrun devicectl`. Not on the App Store — this is my tool, not a product (yet).

## Known limits

CSV export only covers the current day. Chat tab and Text Log tab currently render the same view. Built for one user — me — so multi-device sync, iCloud backup, and timezone travel are explicitly out of scope.
