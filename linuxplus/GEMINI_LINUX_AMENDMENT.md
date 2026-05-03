# GEMINI.md Amendment — Linux+ Study Curriculum
# Append this section to your existing GEMINI.md

---

## Linux+ Study System

### Overview
This amendment defines how Gemini CLI should generate Linux+ study content for Dillon (tp-mudd) on the ThinkPad T14. The calendar sets weekly planning prompts. Claude owns the curriculum and validation. Gemini owns content generation from that curriculum.

### Study Directory Structure
All content lives under a single study directory on the ThinkPad. Gemini should write outputs into the appropriate week subfolder. Assumed structure:

```
~/[your-study-dir]/
├── GEMINI.md               ← Gemini context (this file lives here)
├── GEMINI_LINUX_AMENDMENT.md ← this amendment
├── topic-map.md            ← canonical week-by-week curriculum reference
├── week-01/
│   ├── cheatsheet.md
│   ├── lab-script.sh
│   ├── audit-script.sh
│   ├── notes.md
│   └── testout.md          ← Claude-generated, lives here after validation
├── week-02/
│   └── ...
└── ...
```

Gemini reads `topic-map.md` on every invocation to understand which week is active and what the session targets.

---

### Topic Map Reference
The canonical topic map is stored in `topic-map.md` in the study directory root. It defines all 19 study weeks, their phase, topic, Session A goal, and Session B goal. Gemini must always read this file before generating content for any week.

**Phase structure:**
- Phase 1 (Weeks 1–4): Foundation Revisit — two calendar weeks per study week
- Phase 2 (Weeks 5–14): Core Skills Pipeline
- Phase 3 (Weeks 15–19): Exam Prep

---

### Content Generation Protocol

When prompted to generate content for a week, Gemini produces four files in the correct week folder:

#### 1. `cheatsheet.md` — Session A material
- Lead with the week number, phase, and topic title
- Cover all commands, concepts, and flags relevant to the week's Session A goal
- Format: concept name → what it does → syntax → real example from homelab context
- End with a "quick recall" section: 10–15 commands or concepts, one line each, no explanation — these are for flashcard-style self-testing
- Length: dense but scannable in 45 minutes. No filler. Every line earns its place.

#### 2. `lab-script.sh` — Session B hands-on
- Shebang line, author comment, week/topic header comment
- Each task is a commented block: what it does, why it matters, the command
- Tasks should map directly to the Session B goal in the topic map
- Where possible, reference actual homelab devices by role: ThinkPad (t0), Dell Server (t1), Pi4 (t2), PiZero (t3)
- Include echo statements so Dillon can follow along as the script runs
- Include a DRY_RUN mode at the top: `DRY_RUN=true` — when true, echo commands instead of executing
- End with a summary comment block listing what was practiced

#### 3. `audit-script.sh` — Security/validation angle
- A focused script that audits or validates the week's topic area on the local system
- For permissions weeks: audit suspicious SUID/SGID files, world-writable dirs
- For user management weeks: audit sudo access, locked accounts, password aging
- For SSH weeks: audit sshd_config for insecure settings
- For firewall weeks: dump and review active rules
- Script should produce clean, readable output — not raw dumps
- Include a FINDINGS header in output and flag anything worth attention
- Designed to be re-run anytime, not just during study

#### 4. `notes.md` — Reference and links
- Important man page references for the week's commands
- 2–3 curated external links (Professor Messer, LearnLinuxTV, official docs)
- CompTIA Linux+ XK0-005 exam objective mapping for this week's topic
- "Things that trip people up" — 3–5 common mistakes or exam gotchas for this topic
- A "connect to the homelab" section: one paragraph explaining how this week's topic is already live in Dillon's infrastructure and why that matters

---

### Tone and Style Standards
- Write like a technical mentor, not a textbook
- Assume Dillon is competent — don't over-explain basic Linux concepts he's already covered
- Be specific: reference actual commands, actual paths, actual homelab device roles
- No padding. If a line doesn't add value, cut it.
- Lab scripts should feel like working alongside someone who knows what they're doing, not a tutorial for beginners

---

### Invocation Pattern
When Dillon says: `"Generate week [N] content"` — Gemini should:
1. Read `topic-map.md` to confirm the week's topic, phase, and session goals
2. Generate all four files into `week-[NN]/` (zero-padded)
3. Confirm output with a one-line summary per file

When Dillon says: `"Regenerate week [N] [file]"` — regenerate only that file.

When Dillon says: `"Update topic-map.md"` — Gemini rewrites the topic map based on instructions provided, preserving the established format.

---

### Progress Tracking
At the top of `topic-map.md`, Gemini maintains a simple status table:

| Week | Topic | Content Generated | Session A Done | Session B Done | Tested |
|------|-------|:-----------------:|:--------------:|:--------------:|:------:|
| 1    | File Permissions Pt 1 | ☐ | ☐ | ☐ | ☐ |
| ...  | ...   | ...               | ...            | ...            | ...    |

Dillon updates the checkboxes manually or by telling Gemini: `"Mark week [N] session A complete"`

---

### Integration with Claude Validation
After completing a week's sessions, Dillon submits work to Claude for test-out validation. The `testout.md` file for each week lives in the week's folder. Claude grades it and returns a pass/repeat recommendation. Gemini does not generate testout files — those are Claude's domain.

If Claude returns a repeat recommendation, Gemini may be asked to generate supplemental content: `"Generate week [N] supplemental — weak area: [topic]"` which produces a focused `supplemental-[topic].md` and `supplemental-lab.sh` in the same week folder.
