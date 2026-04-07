---
goal: "Extend Agent Zero with a fully autonomous, self-optimizing affiliate marketing system"
version: "2.0"
date_created: "2026-03-24"
last_updated: "2026-03-25"
owner: "Jose Martinez"
status: "Planned"
tags: ["feature", "affiliate", "seo", "wordpress", "llm-routing", "topic-clusters", "rank-tracking", "two-loop"]
---

# Autonomous Affiliate Marketing System — Agent Zero Extension

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

Extend the existing Agent Zero framework (zero breaking changes, fully additive) to build an autonomous affiliate marketing pipeline operating in **two independent loops**:

- **Weekly production loop** (`affiliate_workflow.py`): discovers commercial/transactional-intent keywords, plans topic clusters, generates SEO content, publishes with internal linking
- **Monthly analysis loop** (`affiliate_analysis_workflow.py`): pulls rank tracking + GA4 data, identifies what actually drives ranking (keyword difficulty range, product category fit), recalibrates difficulty filters, flags declining articles for refresh, makes portfolio decisions

The system learns which **keyword difficulty range** and **product categories** perform on the specific WordPress site — the variables that drive ranking and revenue — not superficial style attributes. Learning is grounded in real rank position data (DataForSEO rank check), not just GA4 traffic which lags by weeks.

---

## 1. Requirements & Constraints

- **REQ-001**: All new files must be additive — no modifications to existing Agent Zero files
- **REQ-002**: Tools must extend `python/helpers/tool.py:Tool` and return `Response(message, break_loop=False)`
- **REQ-003**: Each tool must have a companion prompt file at `prompts/agent.system.tool.<name>.md`
- **REQ-004**: Agent profiles must be created as `usr/agents/<name>/agent.json` with keys `title`, `description`, `context` — `usr/agents/` is the user-owned directory (`USER_AGENTS_DIR` in `subagents.py`); placing profiles there correctly categorises them as user additions (origin="user") rather than framework defaults (origin="default")
- **REQ-005**: Keyword and SERP data sourced exclusively from DataForSEO REST API (credentials via Secrets Manager — stored in `usr/secrets.env`, added via **Web UI → Settings → Secrets**)
- **REQ-006**: Performance analytics sourced exclusively from Google Analytics 4 Data API (credentials via Secrets Manager — stored in `usr/secrets.env`, added via **Web UI → Settings → Secrets**)
- **REQ-007**: WordPress publishing via WP REST API using application password authentication
- **REQ-008**: LLM routing must use existing `chat_model`/`utility_model` split in `AgentConfig` — no new infrastructure
- **REQ-009**: Strategic agents (decisions, classification, analysis) must use `chat_model` (Claude 3.5 Sonnet)
- **REQ-010**: Content agents (generation, rewriting) must use `utility_model` (DeepSeek-V3) via `override_settings` pattern in `initialize_agent()`
- **REQ-011**: All persistent affiliate state stored in `data/affiliate_memory.json` (structured JSON, not FAISS). Schema includes: niches, clusters, articles (with rank history), winning_patterns, difficulty_calibration, experiments
- **REQ-012**: All affiliate credentials stored in Agent Zero's **Secrets Manager** (`usr/secrets.env`) — user adds them via **Web UI → Settings → Secrets** tab. Never stored in source files, `config/*.json`, or the root `.env`. Read in tools via `python/helpers/secrets.py:SecretsManager.get_instance().load_secrets()["KEY"]`
- **REQ-013**: WordPress content must include structured HTML, affiliate links with disclosure, and SEO meta fields
- **REQ-014**: Primary execution via Agent Zero's **Task Scheduler** — two pre-seeded `ScheduledTask` entries in `usr/scheduler/tasks.json`: weekly production and monthly analysis. Both visible in Web UI on first launch. Manual runs via "Run Now" button. No CLI scripts
- **REQ-015**: Keywords must be classified by **search intent** before content creation. Only commercial-investigation ("best X", "X vs Y", "X review", "top X for Y") and transactional ("buy X", "X price", "X deal") keywords qualify. Informational keywords ("how to", "what is", "guide to") are excluded
- **REQ-016**: Articles must be published as part of a **topic cluster** — a pillar page plus supporting articles. Each supporting article links to the pillar; publishing a new article triggers an internal link update in existing cluster articles
- **REQ-017**: Keyword rank positions tracked via `dataforseo_tool action=rank_check` to provide a leading performance indicator — position data is available weeks before GA4 traffic accumulates
- **SEC-001**: Any tool or helper that constructs a file path from an agent-supplied or user-supplied string must sanitise with `safe_filename()` from `python/helpers/security.py`. `AffiliateLinkTool` exempt (no file I/O). `AffiliateMemory` exempt while using a single hardcoded path
- **SEC-002**: WordPress API calls must use HTTPS only; app password via HTTP Basic Auth header
- **SEC-003**: Affiliate credentials read exclusively via `SecretsManager.get_instance().load_secrets()` at call time. Tools validate presence of required keys on each `execute()` and return a descriptive error if missing
- **SEC-004**: The 5 affiliate tools and 11 affiliate agent profiles must not use `code_execution_tool` internally. All external calls go through Python APIs (`requests`, `google-analytics-data` SDK). Restriction scoped to affiliate components only
- **CON-001**: Do not provision WordPress hosting or domains — user provides `WP_URL` via Secrets
- **CON-002**: Spinout = flag `spinout_candidate` in memory only — no hosting API calls
- **CON-003**: `affiliate_workflow.py` and `affiliate_analysis_workflow.py` are Python orchestrators (not agents). They spawn agents directly via `AgentContext(config=config)` + `config.profile = profile` to enable `override_settings`-based LLM routing — a capability `call_subordinate` does not expose. This is the **only** place direct instantiation is used; all in-agent delegation still uses `call_subordinate`
- **CON-004**: Two `ScheduledTask` entries pre-seeded in `usr/scheduler/tasks.json`. No CLI scripts
- **CON-005**: Market selection is a **configuration value** (`config/affiliate_config.json` → `target_market`), not an LLM decision. Default: USA (`location_code=2840`, `language_code="en"`). Multi-market expansion is a future scope change to config, not an MVP feature
- **CON-006**: Metrics computation (score calculation, rank comparison, threshold checks, difficulty calibration) belongs in `python/helpers/affiliate_analytics.py` Python functions — not in agents. Agents are used for judgment only (strategy, content generation, pattern recognition)
- **GUD-001**: Follow YAGNI, KISS, DRY — no speculative features beyond the defined scope
- **GUD-002**: Each tool's `execute()` must handle its own HTTP errors and return descriptive error messages (not raise)
- **GUD-003**: All tool prompt `.md` files must include: description, when to use, argument table, one JSON call example
- **PAT-001**: LLM routing via `initialize_agent(override_settings={...})` — content agents swap `chat_model_*` to point to `util_model_*` values
- **PAT-002**: Agent profiles are passive (JSON only) — all behaviour driven by `context` field injected into system prompt
- **PAT-003**: `AffiliateMemory` uses **synchronous** file I/O (JSON load in `__init__`, atomic write in `_save()`). Synchronous is correct for flat JSON persistence — no async FAISS pattern needed

---

## 2. Implementation Steps

### Phase 1 — Configuration

**GOAL-001**: Establish all non-secret configuration including target market and difficulty calibration defaults

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-001 | Create `config/affiliate_config.json`. Fields: `target_market: {"location_code": 2840, "language_code": "en", "market_name": "USA"}` (CON-005); `wordpress: {default_status: "draft", default_category: "Uncategorized"}`; `publishing: {max_articles_per_run: 5, min_word_count: 800, max_word_count: 2000}`; `keyword_research: {keywords_per_niche: 20, min_monthly_volume: 200, initial_max_difficulty: 25, difficulty_ceiling: 60}`; `niche_filters: {blacklist: ["gambling","adult","weapons","drugs"]}`; `affiliate: {default_network: "amazon"}`; `clusters: {max_supporting_articles: 8, min_supporting_articles: 3}`; `content_optimization: {min_articles_before_analysis: 5, winning_threshold_multiplier: 1.2}`; `portfolio: {spinout_min_monthly_clicks: 500, declining_threshold_weeks: 8}`; `scheduler: {production_cron: "0 9 * * 1", analysis_cron: "0 8 1 * *"}` | | |
| TASK-002 | Document required secrets via **Web UI → Settings → Secrets** (`usr/secrets.env`): `WP_URL`, `WP_USERNAME`, `WP_APP_PASSWORD`, `DATAFORSEO_LOGIN`, `DATAFORSEO_PASSWORD`, `GA4_PROPERTY_ID`, `GA4_SERVICE_ACCOUNT_JSON` (absolute path to service account JSON), `AMAZON_AFFILIATE_TAG`. LLM API keys via **Web UI → Settings → API Keys**: `ANTHROPIC_API_KEY` (chat_model), `DEEPSEEK_API_KEY` (utility_model) | | |

---

### Phase 2 — Memory Helper

**GOAL-002**: JSON persistence for all affiliate state including clusters, rank history, and difficulty calibration

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-003 | Create `python/helpers/affiliate_memory.py` with class `AffiliateMemory`. Path: `data/affiliate_memory.json`. Init: create `data/` if absent, load JSON if exists, else initialise with `{"niches": {}, "clusters": {}, "articles": [], "rank_history": {}, "winning_patterns": {}, "difficulty_calibration": {"current_max": 25, "ranked_below": [], "failed_above": []}, "experiments": []}` | | |
| TASK-004 | `get_niche(name) -> dict` — returns or creates niche record: `{name, status: "exploring", articles_count: 0, total_clicks: 0, primary_cluster_id: null, created_at, updated_at}` | | |
| TASK-005 | `update_niche_status(name, status: Literal["exploring","growing","declining","spinout_candidate"])` — updates status + `updated_at`, persists | | |
| TASK-006 | `get_or_create_cluster(niche, pillar_keyword) -> dict` — returns or creates: `{cluster_id, niche, pillar_keyword, pillar_post_id: null, supporting_keywords: [], supporting_post_ids: [], created_at}`. `cluster_id` = `safe_filename(niche) + "-" + safe_filename(pillar_keyword)` | | |
| TASK-007 | `add_article(record: dict)` — record: `{title, url, wp_post_id, keyword, niche, cluster_id, role: "pillar"|"supporting", published_at, language}`. Appends to `articles`, increments niche `articles_count`, links post_id to cluster | | |
| TASK-008 | `record_rank(wp_post_id, keyword, position: int, date: str)` — appends to `rank_history[str(wp_post_id)]`: `{date, keyword, position}` | | |
| TASK-009 | `update_article_metrics(wp_post_id, metrics: dict)` — updates matching article record with `{sessions, bounce_rate, affiliate_clicks, avg_time_seconds, last_updated}`, persists | | |
| TASK-010 | `save_winning_pattern(niche, pattern: dict)` — pattern: `{keyword_difficulty_range: [min, max], top_product_categories: list[str], avg_article_length: int, confirmed_at}`. Writes to `winning_patterns[niche]`, persists | | |
| TASK-011 | `get_winning_pattern(niche) -> dict|None` — returns `winning_patterns.get(niche)` | | |
| TASK-012 | `update_difficulty_calibration(ranked_difficulty: int|None, failed_difficulty: int|None)` — appends to `ranked_below` / `failed_above` lists; recalculates `current_max` as the 75th percentile of `ranked_below` (capped at config `difficulty_ceiling`) if ≥ 5 ranked data points exist; persists | | |
| TASK-013 | `get_articles_for_refresh() -> list[dict]` — returns articles where the latest two consecutive rank snapshots (from `rank_history`) show position worsened by > 10 places. Rank-based detection only — sessions period comparison removed (it would require two GA4 API calls per article each analysis run; rank position is the designated leading indicator per REQ-017). Computation is pure Python — no LLM | | |
| TASK-014 | `_save()` — atomic write via temp file + `os.replace()` to prevent corruption on crash | | |

---

### Phase 3 — Analytics Helper

**GOAL-003**: All deterministic computation lives here — agents never do arithmetic

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-015 | Create `python/helpers/affiliate_analytics.py`. Functions: `score_keyword(kw: dict) -> float` — `(kw["cpc"] * kw["monthly_volume"]) / max(kw["competition_index"], 1)`; `composite_article_score(article: dict) -> float` — `sessions * (1 - bounce_rate) * (affiliate_clicks + 1)`; `calibrate_difficulty(memory: AffiliateMemory) -> int` — returns `difficulty_calibration["current_max"]` (auto-updated by `update_difficulty_calibration`); `assign_style_rotation(index: int) -> dict` — deterministic style for exploration: rotates `[{tone:"authoritative", structure:"comparison", cta_style:"comparison_table"}, {tone:"conversational", structure:"listicle", cta_style:"inline_text"}, {tone:"expert", structure:"review", cta_style:"button"}]` by `index % 3` | | |

---

### Phase 4 — Tools

**GOAL-004**: Implement all 5 affiliate tools as `Tool` subclasses

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-016 | Create `python/tools/dataforseo_tool.py` (`DataForSEOTool`). Read `DATAFORSEO_LOGIN`/`DATAFORSEO_PASSWORD` from Secrets Manager, Basic Auth, 30s timeout. Actions: **(a)** `keyword_data` — args: `keyword`, `location_code`, `language_code`. POST to `/v3/keywords_data/google_ads/search_volume/live`, return `{keyword, monthly_volume, competition, cpc, competition_index}`; **(b)** `serp_competitors` — args: `keyword`, `location_code`, `language_code`. POST to `/v3/serp/google/organic/live/advanced`, return top 10 result domains; **(c)** `rank_check` — args: `keyword`, `domain` (strip protocol from `WP_URL`). POST to `/v3/serp/google/organic/live/regular` with `depth=100`, scan results for domain match, return `{keyword, position: int|null, url: str|null, date: today_iso}`. All HTTP errors caught and returned as `Response(message="ERROR: <detail>", break_loop=False)` | | |
| TASK-017 | Create `python/tools/affiliate_link_tool.py` (`AffiliateLinkTool`). Read `AMAZON_AFFILIATE_TAG` from Secrets Manager. For `network="amazon"`: construct `https://www.amazon.com/s?k={urllib.parse.quote(product_name)}&tag={tag}`. Return `Response(message=json.dumps({url, product, network}))`. No file I/O — SEC-001 exempt | | |
| TASK-018 | Create `python/tools/wordpress_publisher_tool.py` (`WordPressPublisherTool`). Read `WP_URL`, `WP_USERNAME`, `WP_APP_PASSWORD` from Secrets. Enforce HTTPS. Actions: **(a)** `publish_post` — args: `title`, `content` (HTML), `status="draft"`, `category_name`. POST to `/wp-json/wp/v2/posts`, `Authorization: Basic base64(user:pass)`. Return `{post_id, url, status}`; **(b)** `get_post` — args: `post_id`. GET post HTML content. Return `{post_id, title, content, url}`; **(c)** `update_post` — args: `post_id`, `content` (full new HTML). PATCH post. Return `{post_id, url}`. Private `_get_or_create_category(name)`. All requests 30s timeout | | |
| TASK-019 | Create `python/tools/ga4_analytics_tool.py` (`GA4AnalyticsTool`). Read `GA4_PROPERTY_ID`, `GA4_SERVICE_ACCOUNT_JSON` from Secrets — validate file path exists. Auth via `google.oauth2.service_account.Credentials.from_service_account_file(sa_path)`. Actions: **(a)** `get_post_metrics` — args: `url_path`, `days_ago=30`. GA4 `runReport`, return `{sessions, avg_time_seconds, bounce_rate}`; **(b)** `get_event_count` — args: `event_name="affiliate_click"`, `url_path`, `days_ago=30`. Return event count | | |
| TASK-020 | Create `python/tools/content_optimizer_tool.py` (`ContentOptimizerTool`). Actions: **(a)** `get_winning_pattern` — args: `niche`. Returns `winning_patterns[niche]` JSON or `"No pattern yet for this niche"`; **(b)** `save_winning_pattern` — args: `niche`, `keyword_difficulty_range` (list[int,int]), `top_product_categories` (list[str]), `avg_article_length` (int). Calls `AffiliateMemory.save_winning_pattern()`; **(c)** `get_difficulty_target` — calls `affiliate_analytics.calibrate_difficulty(memory)`, returns current recommended max difficulty as int | | |

---

### Phase 5 — Tool Prompt Descriptions

**GOAL-005**: LLM-visible tool description files so agents know when and how to call each tool

> **Naming rule**: the `tool_name` value in every JSON call example MUST exactly match the Python filename without `.py`. The prompt md filename (e.g., `dataforseo.md`) is independent of the tool filename (`dataforseo_tool.py`). Agents discover tools by filename, so examples must use `"tool_name": "dataforseo_tool"`, not `"tool_name": "dataforseo"`.

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-021 | Create `prompts/agent.system.tool.dataforseo.md` — all 3 actions (`keyword_data`, `serp_competitors`, `rank_check`), args table, one JSON example per action. JSON examples must use `"tool_name": "dataforseo_tool"` | | |
| TASK-022 | Create `prompts/agent.system.tool.affiliate_link.md`. JSON examples must use `"tool_name": "affiliate_link_tool"` | | |
| TASK-023 | Create `prompts/agent.system.tool.wordpress_publisher.md` — all 3 actions (`publish_post`, `get_post`, `update_post`). JSON examples must use `"tool_name": "wordpress_publisher_tool"` | | |
| TASK-024 | Create `prompts/agent.system.tool.ga4_analytics.md`. JSON examples must use `"tool_name": "ga4_analytics_tool"` | | |
| TASK-025 | Create `prompts/agent.system.tool.content_optimizer.md` — all 3 actions including `get_difficulty_target`. JSON examples must use `"tool_name": "content_optimizer_tool"` | | |

---

### Phase 6 — Agent Profiles

**GOAL-006**: Create 11 agent profiles in `usr/agents/`

Strategic (Claude): `affiliate_opportunity`, `topic_cluster_planner`, `content_strategy`, `performance_analysis`, `content_optimization`, `portfolio_manager`, `content_refresh`

Content (DeepSeek): `content_generation`, `experiment_generator`, `wordpress_publisher`, `seo_optimizer`

> **Schema note**: Each `agent.json` must include exactly three fields — `title` (display name), `description` (one-sentence summary shown in Web UI agent selector), and `context` (full system context injected into the agent's prompt). `description` is optional per schema but required here for Web UI discoverability.

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-026 | Create `usr/agents/affiliate_opportunity/agent.json`: `title="Affiliate Opportunity Researcher"`, `description="Discovers commercial-intent keywords, filters by difficulty and volume, and returns scored opportunities for content production."`. `context`: (1) call `content_optimizer_tool action=get_difficulty_target` to fetch current calibrated max; (2) call `dataforseo_tool action=keyword_data` for each candidate keyword using `location_code` and `language_code` from config `target_market`; (3) **intent-classify** — keep only keywords with commercial-investigation signals ("best", "top", "vs", "review", "under $", "for [use-case]", "comparison") or transactional signals ("buy", "price", "deal", "discount", "coupon") — discard informational ("how to", "what is", "guide to", "tutorial"); (4) filter: `monthly_volume ≥ 200`, `competition_index ≤ difficulty_target`, `cpc ≥ 0.5`; (5) call `dataforseo_tool action=serp_competitors` for top 10 survivors; (6) return JSON array sorted by `score = (cpc * monthly_volume) / competition_index` descending | | |
| TASK-027 | Create `usr/agents/topic_cluster_planner/agent.json`: `title="Topic Cluster Planner"`, `description="Plans topic clusters from a keyword list, identifying the pillar article and prioritising supporting article slots."`. `context`: receive niche + qualified keyword list + existing cluster state (if any) passed by caller; identify highest-volume broad keyword as **pillar** topic (or confirm existing pillar if cluster exists); group remaining keywords as **supporting** slots; supporting articles should each cover a specific sub-topic or product type within the niche; return JSON: `{cluster_id, pillar_keyword, pillar_post_id: null|int, supporting_slots: [{keyword, role: "supporting", priority: int, cluster_id}]}` sorted by priority. Priority 1 = publish next | | |
| TASK-028 | Create `usr/agents/content_strategy/agent.json`: `title="Content Strategy Architect"`, `description="Defines content brief for a keyword — tone, structure, length, CTA style, and product categories."`. `context`: receive keyword + niche + cluster_role ("pillar" or "supporting") + winning_pattern (if any); if winning_pattern exists apply its `top_product_categories` and `avg_article_length` as targets; length rule: pillar = "long" (1400–2200w), supporting = "medium" (900–1400w) regardless of pattern; return JSON: `{tone, reading_level, structure, length, cta_style, affiliate_placement, h2_count, product_categories: []}` | | |
| TASK-029 | Create `usr/agents/content_generation/agent.json`: `title="Content Generation Specialist"`, `description="Writes full affiliate articles on the exploitation path (winning pattern confirmed), with internal links and product recommendations."`. `context`: **exploitation path** — receive keyword + strategy + list of existing cluster article `{url, title}` for internal links; write one article following strategy exactly; include ≥ 2 internal links to other cluster articles using natural anchor text; use `affiliate_link_tool` for ≥ 3 product recommendations from `strategy.product_categories`; open with affiliate disclosure paragraph; return HTML body only | | |
| TASK-030 | Create `usr/agents/experiment_generator/agent.json`: `title="Content Experiment Generator"`, `description="Writes batches of exploration articles, each targeting a different keyword with a pre-assigned style rotation."`. `context`: **exploration path** — receive list of `{keyword, tone, structure, cta_style, length, cluster_role, product_categories}` pairs (style pre-assigned by `assign_style_rotation()` in Python — CON-006); for each pair write one complete article targeting that specific keyword with the assigned style; each article targets a **different keyword** — this is intentional to avoid duplicate content and keyword cannibalization while testing which style+category combinations resonate across the niche; use `affiliate_link_tool` for products; return JSON array `[{variant_id, keyword, tone, structure, length, cta_style, html_content}]` where `variant_id = "{keyword_slug}-v{n}"` | | |
| TASK-031 | Create `usr/agents/wordpress_publisher/agent.json`: `title="WordPress Publishing Agent"`, `description="Publishes article HTML to WordPress via the REST API and returns post_id and URL."`. `context`: receive article HTML + title + niche + cluster role; call `wordpress_publisher_tool action=publish_post` with `category_name=niche`; return `{post_id, url}`; on error attempt once with `status=draft` before reporting failure | | |
| TASK-032 | Create `usr/agents/seo_optimizer/agent.json`: `title="SEO Optimisation Specialist"`, `description="Reviews a published article for SEO gaps and applies targeted on-page improvements in-place."`. `context`: receive article HTML + target keyword + GA4 metrics (may be empty for new articles) + rank_position (may be null); check keyword in title/h1/first-100-words, meta description 140–160 chars, internal link count ≥ 2, FAQ schema opportunity; call `wordpress_publisher_tool action=update_post` if improvements are clear; return list of changes made | | |
| TASK-033 | Create `usr/agents/performance_analysis/agent.json`: `title="Performance Analysis Agent"`, `description="Pulls GA4 metrics and rank position for mature articles and returns a raw performance array."`. `context`: receive list of `{wp_post_id, url, keyword}` for articles published > 60 days ago; for each: call `ga4_analytics_tool action=get_post_metrics`, call `ga4_analytics_tool action=get_event_count event_name=affiliate_click`, call `dataforseo_tool action=rank_check` with domain parsed from `WP_URL`; compile and return raw array `[{url, wp_post_id, keyword, sessions, avg_time_seconds, bounce_rate, affiliate_clicks, rank_position}]` — do NOT compute composite_score (CON-006: scoring done by Python workflow). Note: GA4 data for articles < 60 days may be low — this is expected and not an error | | |
| TASK-034 | Create `usr/agents/content_optimization/agent.json`: `title="Content Optimization Analyst"`, `description="Analyses performance data to identify the keyword difficulty range, product categories, and article length that drive ranking, then saves a winning pattern."`. `context`: receive niche + performance array (from performance_analysis agent); analyse: (1) what difficulty range are articles with `rank_position ≤ 30`? (2) which product categories appear in top-performing articles? (3) average word count of articles in positions 1–20?; call `content_optimizer_tool action=save_winning_pattern` with findings; report what was learned and whether the pattern was saved or more data is needed | | |
| TASK-035 | Create `usr/agents/portfolio_manager/agent.json`: `title="Portfolio Manager"`, `description="Evaluates niche performance metrics and recommends portfolio action: scale, audit/refresh, or flag for spinout."`. `context`: receive niche + aggregated metrics summary; apply rules: `growing` if `affiliate_clicks > 50` and rank trend improving over last 4 weeks; `declining` if sessions dropped > 30% for 8+ consecutive weeks; `spinout_candidate` if `monthly_affiliate_clicks ≥ 500` and status = `growing`; output `{niche, new_status, rationale, recommended_action: "continue_experimenting"|"scale_content_production"|"audit_and_refresh"|"flag_for_spinout"}` | | |
| TASK-036 | Create `usr/agents/content_refresh/agent.json`: `title="Content Refresh Specialist"`, `description="Rewrites a declining article with updated product links, current year references, and improved keyword placement."`. `context`: receive article HTML + url + keyword + rank_position + GA4 metrics + published_at date; rewrite to refresh: update product recommendations using `affiliate_link_tool`, update year references, add new sections if content depth is weak, improve keyword placement in h1/first paragraph; call `wordpress_publisher_tool action=update_post` with the refreshed HTML; return summary of changes | | |

---

### Phase 7 — LLM Routing

**GOAL-007**: Config factory for strategic (Claude) vs content (DeepSeek) agents

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-037 | Create `python/helpers/affiliate_llm_router.py`. `get_strategic_config() -> AgentConfig` — `initialize_agent()` with no overrides. `get_content_config() -> AgentConfig` — reads `s = get_settings()`, calls `initialize_agent(override_settings={"chat_model_provider": s["util_model_provider"], "chat_model_name": s["util_model_name"], "chat_model_api_base": s.get("util_model_api_base",""), "chat_model_ctx_length": s["util_model_ctx_length"]})`. Note: `chat_model_vision` and `chat_model_kwargs` inherit from chat_model settings — safe because content prompts contain no images and `chat_model_kwargs` should be empty | | |
| TASK-038 | Document model setup: `chat_model` = Anthropic / `claude-3-5-sonnet-20241022`; `utility_model` = DeepSeek / `deepseek/deepseek-chat` — configured via **Web UI → Settings**. API keys via **Web UI → Settings → API Keys** | | |

---

### Phase 8 — Weekly Production Workflow

**GOAL-008**: Python orchestrator for the weekly content production loop

Strategic agents (Claude): `affiliate_opportunity`, `topic_cluster_planner`, `content_strategy`
Content agents (DeepSeek): `content_generation`, `experiment_generator`, `wordpress_publisher`

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-039 | Create `python/affiliate_workflow.py` header — imports: `Agent`, `AgentContext`, `UserMessage` from `agent`, `initialize_agent` from `initialize`, `AffiliateMemory`, `affiliate_analytics`, `affiliate_llm_router`, json config loader, `PrintStyle`, stdlib | | |
| TASK-040 | Implement `_make_strategic_agent(profile: str) -> Agent` and `_make_content_agent(profile: str) -> Agent` — call respective config getters, set `config.profile = profile`, return `AgentContext(config=config).agent0` | | |
| TASK-041 | Implement `async _run_agent_phase(agent: Agent, prompt: str) -> str` — `agent.hist_add_user_message(UserMessage(message=prompt))`, await `agent.monologue()`, return result. Named `_run_agent_phase` (not `_run_task`) to avoid shadowing `TaskScheduler._run_task` | | |
| TASK-042 | Implement `_extract_json(text: str) -> dict|list|None` — `re.search(r'\{.*\}|\[.*\]', text, re.DOTALL)` + `json.loads()`, return None on failure | | |
| TASK-043 | Implement `async phase_opportunity(niche: str, memory: AffiliateMemory) -> list[dict]` — creates strategic agent `affiliate_opportunity`; prompt includes niche + `calibrate_difficulty(memory)` result; returns intent-classified, difficulty-filtered keyword list sorted by score desc | | |
| TASK-044 | Implement `async phase_cluster_plan(niche: str, keywords: list[dict], memory: AffiliateMemory) -> dict` — creates strategic agent `topic_cluster_planner`; passes existing cluster state from memory; returns `{cluster_id, pillar_keyword, pillar_post_id, supporting_slots: [{keyword, priority, cluster_id}]}` | | |
| TASK-045 | Implement `async phase_content_strategy(niche: str, keyword: str, cluster_role: str, memory: AffiliateMemory) -> dict` — creates strategic agent `content_strategy`; passes `memory.get_winning_pattern(niche)` if exists; returns strategy dict | | |
| TASK-046 | Implement `async phase_generate_content(niche: str, keyword_slots: list[dict], memory: AffiliateMemory) -> list[dict]` — **branches on winning pattern**: exploitation (pattern exists) → for each slot calls `content_generation` with winning strategy + cluster article links; exploration (no pattern) → calls `assign_style_rotation(i)` for each slot (Python, no LLM), sends full list to `experiment_generator` in one call; returns `[{variant_id, keyword, html_content, tone, structure, cta_style, cluster_role}]` | | |
| TASK-047 | Implement `async phase_publish(memory: AffiliateMemory, niche: str, cluster: dict, articles: list[dict]) -> list[dict]` — for each article: creates content agent `wordpress_publisher`; publishes; calls `memory.add_article()`; after all publish calls complete, calls `phase_internal_links()`; returns `[{variant_id, wp_post_id, url, keyword}]` | | |
| TASK-048 | Implement `async phase_internal_links(cluster_id: str, new_articles: list[dict], memory: AffiliateMemory) -> None` — reads `WP_URL`, `WP_USERNAME`, `WP_APP_PASSWORD` from `SecretsManager.get_instance().load_secrets()` at call time; for each article already in the cluster (pre-existing): fetches post HTML via `requests.get(f"{wp_url}/wp-json/wp/v2/posts/{post_id}", auth=(user, pass))`; inserts a contextual `<a href="{new_url}">{anchor_text}</a>` link near the first relevant paragraph; PATCHes back. Maximum 3 new links inserted per existing post. Pure Python — no agent, no LLM needed for link insertion. RISK-007: if WP uses Gutenberg blocks, wrap injected link in `<!-- wp:html -->` block | | |
| TASK-049 | Implement `async run_production(niche: str, num_articles: int = 3) -> dict` — orchestrator: opportunity → cluster_plan → (for each of top `num_articles` keyword slots: content_strategy + generate_content) → publish → internal_links → return `{niche, mode: "exploration"|"exploitation", articles_published: [{title, url, keyword, variant_id}], total_runtime_seconds}`. Per-phase try/except: failure logs warning, continues | | |

---

### Phase 9 — Monthly Analysis Workflow

**GOAL-009**: Python orchestrator for the monthly performance analysis and learning loop

Strategic agents (Claude): `performance_analysis`, `content_optimization`, `portfolio_manager`, `content_refresh`

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-050 | Create `python/affiliate_analysis_workflow.py` header — same imports as production workflow | | |
| TASK-051 | Implement `async phase_pull_performance(niche: str, memory: AffiliateMemory) -> list[dict]` — creates strategic agent `performance_analysis`; passes all niche articles published > 60 days ago; agent calls GA4 + rank_check for each; returns raw performance array (no composite_score); Python workflow then calls `affiliate_analytics.composite_article_score()` for each dict, adds `composite_score` field, sorts by composite_score desc (CON-006); calls `memory.update_article_metrics()` and `memory.record_rank()` per result | | |
| TASK-052 | Implement `async phase_analyse_patterns(niche: str, performance: list[dict], memory: AffiliateMemory) -> dict` — creates strategic agent `content_optimization`; passes performance array; agent identifies difficulty range of ranked articles, top product categories, avg length in positions 1–30; returns winning_pattern; calls `memory.save_winning_pattern()` and `memory.update_difficulty_calibration()` | | |
| TASK-053 | Implement `async phase_refresh_declining(memory: AffiliateMemory) -> list[str]` — calls `memory.get_articles_for_refresh()` (Python, no LLM — CON-006); for each returned article: fetches current post HTML via GET `wordpress_publisher_tool`; creates strategic agent `content_refresh`; sends HTML + metrics + keyword; agent rewrites and calls `wordpress_publisher_tool action=update_post`; returns list of refreshed URLs | | |
| TASK-054 | Implement `async phase_portfolio(niche: str, performance: list[dict], memory: AffiliateMemory) -> dict` — creates strategic agent `portfolio_manager`; returns decision dict; calls `memory.update_niche_status()` | | |
| TASK-055 | Implement `async run_analysis(niche: str) -> dict` — orchestrator: pull_performance → analyse_patterns → refresh_declining → portfolio; returns `{niche, articles_analysed, patterns_saved, articles_refreshed, portfolio_decision, total_runtime_seconds}`. Per-phase try/except | | |

---

### Phase 10 — Pre-seeded Scheduler Tasks

**GOAL-010**: Two tasks in `usr/scheduler/tasks.json` visible in Web UI from first launch

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-056 | Create `usr/scheduler/tasks.json` with two `ScheduledTask` entries in `{"tasks": [...]}`. Both follow `BaseTask` + `ScheduledTask` schema: `uuid` (fixed UUID v4), `context_id` (= uuid), `type: "scheduled"`, `state: "idle"`, `attachments: []`, `project_name: null`, `project_color: null`, `last_run: null`, `last_result: null`. **Task 1** (production): `name: "Affiliate Production"`, `schedule: {"minute":"0","hour":"9","day":"*","month":"*","weekday":"1","timezone":"UTC"}`. **Task 2** (analysis): `name: "Affiliate Analysis"`, `schedule: {"minute":"0","hour":"8","day":"1","month":"*","weekday":"*","timezone":"UTC"}` | | |
| TASK-057 | Define `system_prompt` and `prompt` for **Affiliate Production** task. `system_prompt`: `"You are an autonomous affiliate marketing production agent. Use code_execution_tool with runtime=python to run the production workflow and report the summary when complete."` `prompt`: `"Run the affiliate production workflow:\n\nimport asyncio\nfrom python.affiliate_workflow import run_production\nresult = asyncio.run(run_production(niche='best home office equipment', num_articles=3))\nprint(result)\n\nEdit niche and num_articles to customise."` Note: SEC-004 restricts the 5 tools and 11 profiles — it does not restrict this entry-point scheduler agent | | |
| TASK-058 | Define `system_prompt` and `prompt` for **Affiliate Analysis** task. `system_prompt`: `"You are an autonomous affiliate marketing analysis agent. Use code_execution_tool with runtime=python to run the monthly analysis workflow and report the results."` `prompt`: `"Run the affiliate analysis workflow:\n\nimport asyncio\nfrom python.affiliate_analysis_workflow import run_analysis\nresult = asyncio.run(run_analysis(niche='best home office equipment'))\nprint(result)\n\nEdit niche to match your production task."` | | |

---

### Phase 11 — Dependencies

**GOAL-011**: Add required packages without disrupting base install

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-059 | Create `requirements.affiliate.txt`: `google-analytics-data>=0.18.0`, `requests>=2.32.0`. Do NOT add to `requirements.txt`. Install: `pip install -r requirements.affiliate.txt` | | |

---

### Phase 12 — Validation

**GOAL-012**: Verify complete system end-to-end

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-060 | Dry-run: start Agent Zero, open **Web UI → Scheduler** — verify both "Affiliate Production" and "Affiliate Analysis" tasks visible with `idle` state and correct cron schedules | | |
| TASK-061 | Import test: `python -c "from python.tools.dataforseo_tool import DataForSEOTool; print('OK')"` for all 5 tools | | |
| TASK-062 | Analytics helper test: `python -c "from python.helpers.affiliate_analytics import score_keyword, assign_style_rotation; print(score_keyword({'cpc':1.5,'monthly_volume':500,'competition_index':30})); print(assign_style_rotation(0), assign_style_rotation(1), assign_style_rotation(2))"` | | |
| TASK-063 | Memory test: instantiate `AffiliateMemory`, create cluster, add article, call `update_difficulty_calibration(ranked_difficulty=22)` × 5, verify `calibrate_difficulty()` updates `current_max`, reload from disk and verify persistence | | |
| TASK-064 | Secrets test: add `WP_URL=https://test.example.com` via Web UI Secrets, verify `SecretsManager.get_instance().load_secrets().get("WP_URL")` returns it | | |
| TASK-065 | Intent filter test: trigger "Affiliate Production" via "Run Now", verify at least one informational keyword was excluded in agent logs | | |
| TASK-066 | Cluster + internal linking test: publish 2 articles to same cluster, verify each post's HTML contains a link to the other | | |
| TASK-067 | Full production MVP: all secrets configured, trigger "Affiliate Production" via Run Now, verify ≥ 3 articles in WP as drafts, `data/affiliate_memory.json` exists with niche + cluster + article records | | |
| TASK-068 | Full analysis MVP: trigger "Affiliate Analysis" via Run Now (adjust `days_ago` or use test articles), verify rank data recorded in memory, winning_pattern saved or "insufficient data" noted | | |

---

## 3. Alternatives

- **ALT-001**: Custom LLM router class — rejected; `initialize_agent(override_settings)` uses 100% existing infrastructure
- **ALT-002**: FAISS memory — rejected; affiliate data is structured (clusters, ranks, patterns), not semantic; JSON is simpler and human-readable
- **ALT-003**: Single scheduler task — rejected; production (weekly) and analysis (monthly) have different cadences and resource profiles. Merging them would either over-run analysis or under-run production
- **ALT-004**: `call_subordinate` inside workflows — rejected; `affiliate_workflow.py` needs `override_settings` LLM routing which `call_subordinate` does not expose (see CON-003)
- **ALT-005**: SearXNG for keyword data — rejected; provides no volume/CPC/difficulty numbers
- **ALT-006**: Single monolithic agent — rejected; specialised profiles + LLM cost routing is the Agent Zero pattern
- **ALT-007**: CLI scripts — rejected; Web UI Run Now makes them redundant
- **ALT-008**: Market selection agent — rejected; market is a config value (CON-005). Multi-market is a future config change
- **ALT-009**: Metrics computation in agents — rejected; deterministic scoring belongs in Python (CON-006). LLMs add cost and hallucination risk for arithmetic
- **ALT-010**: Optimising writing tone/style as the learning signal — rejected; writing style is a third-order factor. Keyword difficulty range and product category fit are what actually drive ranking and revenue. Style diversity in the exploration phase tests category resonance, not tone preference

---

## 4. Dependencies

- **DEP-001**: `google-analytics-data` — GA4 Data API client
- **DEP-002**: `requests` — DataForSEO + WordPress REST API calls
- **DEP-003**: Anthropic API key (`ANTHROPIC_API_KEY`) → **Web UI → Settings → API Keys**
- **DEP-004**: DeepSeek API key (`DEEPSEEK_API_KEY`) → **Web UI → Settings → API Keys**
- **DEP-005**: DataForSEO credentials (`DATAFORSEO_LOGIN`, `DATAFORSEO_PASSWORD`) → **Web UI → Settings → Secrets**
- **DEP-006**: Google Cloud service account JSON path (`GA4_SERVICE_ACCOUNT_JSON`) → **Web UI → Settings → Secrets**
- **DEP-007**: GA4 Property ID (`GA4_PROPERTY_ID`) → **Web UI → Settings → Secrets**
- **DEP-008**: WordPress credentials (`WP_URL`, `WP_USERNAME`, `WP_APP_PASSWORD`) → **Web UI → Settings → Secrets**
- **DEP-009**: Amazon Associates tag (`AMAZON_AFFILIATE_TAG`) → **Web UI → Settings → Secrets**

---

## 5. Files

**New files — zero existing files modified:**

- **FILE-001**: `config/affiliate_config.json` — target_market, difficulty calibration defaults, cluster config
- **FILE-002**: `python/helpers/affiliate_memory.py` — JSON persistence (niches, clusters, articles, rank_history, winning_patterns, difficulty_calibration)
- **FILE-003**: `python/helpers/affiliate_analytics.py` — scoring, calibration, style rotation, refresh detection (pure Python, no LLM)
- **FILE-004**: `python/helpers/affiliate_llm_router.py` — strategic vs content AgentConfig factory
- **FILE-005**: `python/tools/dataforseo_tool.py` — `keyword_data` + `serp_competitors` + `rank_check`
- **FILE-006**: `python/tools/affiliate_link_tool.py`
- **FILE-007**: `python/tools/wordpress_publisher_tool.py` — `publish_post` + `get_post` + `update_post`
- **FILE-008**: `python/tools/ga4_analytics_tool.py`
- **FILE-009**: `python/tools/content_optimizer_tool.py` — `get/save_winning_pattern` + `get_difficulty_target`
- **FILE-010**: `prompts/agent.system.tool.dataforseo.md`
- **FILE-011**: `prompts/agent.system.tool.affiliate_link.md`
- **FILE-012**: `prompts/agent.system.tool.wordpress_publisher.md`
- **FILE-013**: `prompts/agent.system.tool.ga4_analytics.md`
- **FILE-014**: `prompts/agent.system.tool.content_optimizer.md`
- **FILE-015**: `usr/agents/affiliate_opportunity/agent.json` — intent-classifying, difficulty-aware researcher
- **FILE-016**: `usr/agents/topic_cluster_planner/agent.json` — pillar + supporting cluster architect
- **FILE-017**: `usr/agents/content_strategy/agent.json`
- **FILE-018**: `usr/agents/content_generation/agent.json` — exploitation path (confirmed winning pattern)
- **FILE-019**: `usr/agents/experiment_generator/agent.json` — exploration path (different keywords, assigned styles)
- **FILE-020**: `usr/agents/wordpress_publisher/agent.json`
- **FILE-021**: `usr/agents/seo_optimizer/agent.json`
- **FILE-022**: `usr/agents/performance_analysis/agent.json` — GA4 + rank tracking combined
- **FILE-023**: `usr/agents/content_optimization/agent.json` — learns difficulty range + product categories
- **FILE-024**: `usr/agents/portfolio_manager/agent.json`
- **FILE-025**: `usr/agents/content_refresh/agent.json` — rewrites declining articles
- **FILE-026**: `python/affiliate_workflow.py` — weekly production orchestrator
- **FILE-027**: `python/affiliate_analysis_workflow.py` — monthly analysis orchestrator
- **FILE-028**: `usr/scheduler/tasks.json` — two pre-seeded ScheduledTask entries
- **FILE-029**: `requirements.affiliate.txt`

---

## 6. Testing

- **TEST-001**: Both scheduler tasks visible in Web UI with correct cron schedules
- **TEST-002**: Import test for all 5 tools — no import errors
- **TEST-003**: `affiliate_analytics.score_keyword()` returns correct float
- **TEST-004**: `affiliate_analytics.assign_style_rotation(0/1/2)` returns 3 distinct style dicts
- **TEST-005**: `AffiliateMemory` — cluster creation, article linking, rank recording, difficulty calibration, refresh detection
- **TEST-006**: Secrets read test via SecretsManager
- **TEST-007**: Intent filter — informational keyword excluded in production agent logs
- **TEST-008**: Cluster internal linking — 2 articles in same cluster cross-link after publication
- **TEST-009**: Full production MVP — ≥ 3 articles in WP as drafts, memory has niche + cluster + article records
- **TEST-010**: Full analysis MVP — rank data recorded, winning_pattern saved or "insufficient data" noted

---

## 7. Risks & Assumptions

- **RISK-001**: Agent JSON parsing — `_extract_json()` regex fallback; phase failures non-fatal, log and continue
- **RISK-002**: DataForSEO rate limits — 20 keywords/run max; `rank_check` batched once monthly only
- **RISK-003**: GA4 data lag 24–48h; rank settling takes 4–8 weeks; analysis workflow targets articles > 60 days old
- **RISK-004**: WordPress REST API disabled by some managed hosts — tool returns clear error message
- **RISK-005**: LLM context overflow — `experiment_generator` batches all keywords in one call but each is a standalone article; context limit risk mitigated by `max_articles_per_run=5`
- **RISK-006**: Difficulty calibration cold start — `initial_max_difficulty=25` is conservative; auto-calibration activates after 5+ ranked articles (typically months 2–3)
- **RISK-007**: Internal link insertion may break Gutenberg block-based themes — `update_post` sends raw HTML. If the WP site uses Gutenberg blocks, HTML must be wrapped in `<!-- wp:html -->`. Documented as implementation note in TASK-048
- **RISK-008**: `rank_check` scans 100 SERP results per keyword per call — if site has very low DA, articles may not appear in top 100. `position: null` is treated as "not yet ranking" (not an error)
- **ASSUMPTION-001**: All affiliate credentials configured via Web UI before first run
- **ASSUMPTION-002**: WordPress REST API enabled (default WP 5.0+), Application Password created
- **ASSUMPTION-003**: GA4 property exists with tag installed (Site Kit plugin or manual GTM)
- **ASSUMPTION-004**: DeepSeek configured as `utility_model` via **Web UI → Settings**
- **ASSUMPTION-005**: Affiliate clicks tracked as custom GA4 event `affiliate_click` — user must configure this in WP theme or GTM
- **ASSUMPTION-006**: Meaningful rank/traffic data only after 2–4 months; system is designed for ongoing operation, not immediate results

---

## 8. Related Specifications / Further Reading

- [Agent Zero Architecture Blueprint](../docs/Project_Architecture_Blueprint.md)
- [Agent Zero copilot-instructions](../.github/copilot-instructions.md)
