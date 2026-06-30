Every Sunday — The Ritual (in order):

1. Open sunday-ritual.md. Answer the three questions. Schedule two time blocks in Google Calendar — not the content itself, just protected time slots labeled "Linux+ Week N Session A" and "Linux+ Week N Session B."
2. Tell Gemini: "Generate week [N] content" — Gemini reads GEMINI_LINUX_AMENDMENT.md and topic-map.md, then writes four files into linuxplus/week-NN/: cheatsheet.md, lab-script.sh, audit-script.sh, notes.md. Those files are the actual study material.
3. That's it for Sunday. Planning is done.

---
During the week — Two sessions:

- Session A (45 min): Read cheatsheet.md. Nothing else. No terminal, no lab. Concept absorption only.
- Session B (45–60 min): Run lab-script.sh on the homelab. Read notes.md for context.

---
After both sessions — Test-out with Claude:

Come here and say: "Test me out on Week N". I'll quiz you on the objectives for that week. Pass → you update the checkbox in topic-map.md and move on. Repeat → I'll identify the gap, you tell Gemini to generate supplemental content for that specific topic.

---
What doesn't go in the calendar: Gemini's output. The calendar only holds two things — the day and time you're showing up to study. The content lives in the files.

Does that match what you're able to run every week given your work schedule?