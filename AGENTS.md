# Repo instructions

1. Before ANY work, read `AAROGYAMP-REFERENCE.md` (full spec) and `AAROGYAMP-WORKPLAN.md` (who owns what).
2. You are assisting ONE person. Only modify files listed under their ownership in `AAROGYAMP-WORKPLAN.md` §File Ownership Map. If a needed change falls outside, STOP and tell the human to coordinate.
3. API shapes and the LLM JSON schema are frozen per Reference doc §6, §9, §11. Do not invent new fields.
4. Never modify `server/app/data/emergency_rules.yaml` thresholds or keyword lists without an explicit human instruction confirming clinical sign-off has been obtained — flag the requirement rather than assuming it or making the edit yourself.
5. Do not add features listed in Reference doc §17 (out of scope), and never write UI copy, prompts, or docs that state or imply a confirmed diagnosis — see Reference §18. All AI-generated assessments must read as "possible conditions," not fact.
6. Never let the AI layer fabricate a doctor, clinic, phone number, or address — doctor data comes only from verified records (Reference §3, §11).
7. After changes, run the verification command for that milestone from `AAROGYAMP-WORKPLAN.md` and paste results.
8. At the end of every session, add an entry to `DEVLOG.md` (newest at top) summarizing what was done, how, and any gotchas — the next person's AI reads it before starting.
