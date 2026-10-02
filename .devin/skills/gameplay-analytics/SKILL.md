---
name: gameplay-analytics
description: Event taxonomy, cohort reading, weekly dashboard layout, and experiment hygiene for a live Roblox game. Use for instrumentation plans, weekly live-ops reports, and A/B design.
sources: [original, https://create.roblox.com/docs/production/analytics]
---

# Gameplay analytics

## When to Load

`10-analyste-liveops` for reports and experiments; `04` when adding `AnalyticsService` calls; `02` when writing the Measure section of a spec.

## Quick Reference

### Event taxonomy (fits AnalyticsService limits: 100 custom events, 10 funnels, 3 custom fields)

| Family | Event | When logged | Fields (max 3) |
|--------|-------|-------------|----------------|
| Funnel `onboarding` | steps 1..N from spec | after the step is actually completed, server-side | platform |
| Funnel `shop` | open, select, prompt, granted | after each confirmed state | platform, sku |
| Economy | source / sink per currency | after the authoritative mutation commits, with the returned balance | sku, context |
| Custom | `session_end` with duration bucket | PlayerRemoving | platform, zone |
| Custom | `error_<system>` | after recovery, rate limited | code |

Rules: log after success, never on attempt; server-side for anything that matters; stay under 120 + 20 x CCU calls per minute; never recompute balances from `leaderstats`.

### Weekly report columns

Date range, DAU, new vs returning, D1 / D7 / D30 by platform, median session, sessions per DAU, first-play bounce, funnel `onboarding` drop by step, sink/source ratio per currency, ARPDAU, ARPPU, top 3 errors. Each number has a dashboard screenshot or export; no number without a source.

### Reading signals

Find the narrowest broken transition: impression -> play (thumbnail, PTR), join -> control (load time, FTUE), action -> payoff (first reward time), return (D1), purchase (prompt -> granted). Propose a measured problem to the designer, not a mechanic.

### Experiments

Write before launch: hypothesis "if Y changes because of Z, X moves without harming G", primary metric, counter-metrics, minimum detectable effect, duration, decision rule. No peeking; stop early only for safety or broken instrumentation. Thumbnail A/B: 2 variants minimum, read CTR / PTR on the experience page, 7 days or 10k impressions minimum.

### Dashboards lag

Creator Hub events appear after about 24 hours; use the real-time event viewer for validation only. Launch stats on ad traffic look worse than organic; low CCU numbers are noise.
