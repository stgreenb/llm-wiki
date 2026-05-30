# L1/L2 Routing Rules
# Governs what lives in Claude Memory (L1) vs the Logseq Wiki (L2)
# Read at the start of every session. Never put secrets here.

## The Core Question

Before writing anything, ask:
> "Would Claude making a bad call without this knowledge be embarrassing or disruptive in real-time?"

- YES → L1 (Memory, this file and its siblings)
- NO  → L2 (Wiki, ingested via `/wiki ingest`, queried via `/wiki query`)

The goal: L1 stays lean and fast. L2 grows without limit.

---

## What Goes in L1

### 1. Identity & Alias Mappings
Short-forms, nicknames, and org abbreviations that appear constantly in meeting notes.
Store them here so the LLM never misattributes an action item.

Examples:
- "JD" = [[Wiki/People/Jane-Doe]] (Engineering Lead, Acme Corp)
- "the board" = refers to [[Wiki/Projects/Project-Cobra]] steering committee
- "ops team" = [[Wiki/People/Alice-Smith]], [[Wiki/People/Bob-Jones]]

### 2. Recurring Meeting Cadences
Regular meetings with their owners and default attendees.
Store here so `/wiki ingest` can pre-populate attendees:: without asking.

Format:
  MEETING_NAME | DAY/FREQUENCY | DEFAULT_ATTENDEES | LINKED_PROJECT
Examples:
- Alpha Sync | Every Monday 10am | JD, Alice, Bob | [[Wiki/Projects/Project-Alpha]]
- Cobra SteerCo | First Friday of month | CEO, JD, PM | [[Wiki/Projects/Project-Cobra]]
- Weekly Ops Review | Thursday 2pm | Ops team | [[Wiki/Projects/Operations]]

### 3. Active Blocker Flags
Critical project-level blockers that affect every session's reasoning.
Remove entries here as soon as the blocker is resolved.

Format:  PROJECT | BLOCKER_SUMMARY | SINCE
Examples:
- Project Cobra | On hold: awaiting legal sign-off on vendor contract | 2026-05-01
- Project Alpha | Deployment frozen: infra migration in progress | 2026-05-20

### 4. Tracker & Tool URLs
The exact URLs for project trackers, boards, and wikis.
Store here so the LLM can include them in action items without asking.

Format:  PROJECT | TOOL | URL
Examples:
- Project Alpha | Jira | https://acme.atlassian.net/jira/software/projects/ALPHA
- Project Cobra | Notion | https://notion.so/acme/cobra-XXXX
- All Projects  | Confluence | https://acme.atlassian.net/wiki

### 5. Standing Preferences & Conventions
Hard rules about how action items and meeting notes should be formatted,
attributed, or distributed. Override the schema defaults here.

Examples:
- Alice Smith prefers action items emailed to her, not added to Jira
- All action items from SteerCo must include a "Decision Required by" date
- Meeting notes for external clients must omit internal cost figures
- Default owner for unattributed ops actions: [[Wiki/People/Alice-Smith]]

### 6. Current Sprint / Cycle Context
The active sprint or planning period across projects.
Update at the start of each sprint. Helps the LLM assess "is this due soon?"

Format:  PROJECT | SPRINT/CYCLE | START | END
Examples:
- Project Alpha | Sprint 12 | 2026-05-26 | 2026-06-06
- Project Cobra | Phase 2 kickoff | 2026-06-01 | 2026-07-31

---

## What Goes in L2 (Wiki Only)

| Information | Wiki Location |
|---|---|
| Full meeting notes and transcripts | `Wiki/Meetings/YYYY-MM-DD-Name.md` |
| Action register per project | `Wiki/Actions/ProjectName.md` |
| Closed/done action history | Bottom section of `Wiki/Actions/ProjectName.md` |
| Project context, goals, timeline | `Wiki/Projects/ProjectName.md` |
| Individual decisions and rationale | `Wiki/Decisions/DecisionSlug.md` |
| Person profiles and contact context | `Wiki/People/FirstName-LastName.md` |
| Process how-tos and reference docs | `Wiki/Reference/TopicName.md` |
| Retro notes and lessons learned | `Wiki/Reference/Retros/YYYY-MM-DD.md` |

---

## Routing Decision Table

Use this table when unsure where to put something.

| Information Type | Frequency of Need | L1 or L2? | Notes |
|---|---|---|---|
| "JD" means Jane Doe | Every meeting ingest | L1 | Alias mapping |
| Jane Doe's full background | Occasionally | L2 | `Wiki/People/Jane-Doe.md` |
| Project Cobra is blocked | Every session until resolved | L1 | Remove once unblocked |
| Why Cobra was blocked | Historical record | L2 | `Wiki/Projects/Project-Cobra.md` |
| Jira board URL for Alpha | Every action item write | L1 | Tracker URL |
| All of Alpha's open actions | Pre-meeting prep | L2 | `/wiki query "open actions Alpha"` |
| "Alice gets actions by email" | Every action item | L1 | Standing preference |
| Alice's full stakeholder history | Occasionally | L2 | `Wiki/People/Alice-Smith.md` |
| Current sprint end date | Due-date assessment | L1 | Sprint context |
| Sprint retrospective notes | Retrospectives only | L2 | `Wiki/Reference/Retros/` |
| A new process gotcha (critical) | Could arise anytime | L1 | Remove if it becomes niche |
| A process how-to guide | On demand | L2 | `Wiki/Reference/TopicName.md` |

---

## L1 Hygiene Rules

1. **Remove resolved blockers immediately.** Stale blocker flags cause the LLM to give wrong advice.
2. **Alias mappings must be bidirectional.** If "JD" = Jane Doe, also note Jane Doe's preferred short-form.
3. **Sprint context expires every cycle.** Update L1 at sprint start; never leave stale dates.
4. **No secrets.** API keys, passwords, personal salaries, and medical information are NEVER in L1 or L2.
5. **No duplicates.** If the same fact is in both L1 and L2, `/wiki lint` will flag it. Resolve by keeping
   the operational shorthand in L1 and the full context in L2.
6. **L1 entry limit.** If this file exceeds ~80 meaningful entries, audit and prune. Speed degrades
   when context is too large.

---

## Ingest Routing Checklist

When running `/wiki ingest` on new meeting notes, apply these checks before writing:

- [ ] Are any attendees new? → Create `Wiki/People/Name.md` and add alias to L1 if they appear often
- [ ] Are there new projects mentioned? → Create `Wiki/Projects/Name.md` and `Wiki/Actions/Name.md`
- [ ] Are there blockers that affect every future session? → Add to L1 blocker flags
- [ ] Are there new tracker URLs? → Add to L1 tracker URLs
- [ ] Are there standing preference changes? → Update L1 preferences
- [ ] Are there decisions made? → Create `Wiki/Decisions/Slug.md`
- [ ] Does the meeting page reference all attendees with [[Wiki/People/...]] links?
- [ ] Is every action item assigned an action-id:: and owner::?
- [ ] Has the relevant action register page been updated?
- [ ] Has the relevant project page been updated with any status change?
- [ ] Set status:: processed on the meeting page

---

## Example: Post-Meeting Routing Decision

Meeting note excerpt:
> "Bob confirmed Project Cobra is still blocked on legal. JD to chase vendor by EOW.
>  Alice will update the Jira board. Next SteerCo pushed to June 13."

Routing:
- "JD" alias → already in L1, no change needed
- "Cobra blocked on legal" → already in L1 blockers; update date if changed
- "JD to chase vendor" → new action item → append to `Wiki/Actions/Project-Cobra.md`
  with owner:: [[Wiki/People/Jane-Doe]], due:: 2026-05-31 (EOW), status:: open
- "Alice update Jira board" → new action item → same register, owner:: [[Wiki/People/Alice-Smith]]
- "SteerCo pushed to June 13" → update L1 recurring meeting cadence for Cobra SteerCo
- Full meeting transcript → `Wiki/Meetings/2026-05-30-Cobra-SteerCo.md`, status:: processed
