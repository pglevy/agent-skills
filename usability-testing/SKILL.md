---
name: usability-testing
description: "Guide designers through usability testing for a specific feature. Use when a designer asks for help with: prepping a usability test, drafting a test script or task scenarios, writing study questions, setting up session notes, or summarizing findings from completed sessions. Covers the full arc: objectives, script, tasks, questions, findings report."
metadata:
  title: Usability Testing
  prompt: "Help me set up usability testing for this project: "
  tags:
    - Define
    - Deliver
  human-reviewer: Philip Levy
  last-reviewed: 2026-05-22 
---

# Usability Testing

This skill guides a designer through preparing, running, and synthesizing a usability test for a specific feature.

## Phases

```
1. Setup       → gather feature context, objectives, prototype
2. Prep        → draft script, tasks, and questions  [USER APPROVAL]
3. Synthesis   → summarize session notes into findings report
```

---

## Phase 1: Setup

Ask these questions to gather context. Ask them conversationally — don't dump a form. If the designer already provided some answers in their initial message, skip those.

**Required context:**
- What feature or flow is being tested?
- Who is the target persona(s)? (role, experience level, familiarity with the product)
- What are the 1–3 objectives? What specific behaviors or decisions does this test need to inform?
- Do you have a prototype link? (If not, note this — tasks will be written as placeholders)
- Any known risks or hypotheses going in?

Once you have enough to proceed, move to Phase 2. Don't wait for every answer if the designer says "just get started."

---

## Phase 2: Prep

Generate the full test package as a single deliverable. Structure it as sections the designer can copy directly into their doc or share with their team.

### Intro Script

Four talking points, each with a concrete example line:

1. **Set the object of the test** — "We're testing the design, not you. There are no right or wrong answers."
2. **Disclose the prototype stage** — "This is a prototype, so not everything is functional. Use it as you would the real thing."
3. **Invite questions** — "Any questions before we start?"
4. **Ask to record** — "Is it alright if we record this session so we can review your feedback later?"

### Background Questions (Before Test)

Write 4–5 questions tailored to the persona and feature. Always include:
- Familiarity with the product or domain
- Current role and main tasks
- How often they encounter this type of workflow today

### Tasks (2–4 Tasks)

Each task should:
- Be scenario-framed, not instructional ("Imagine you need to… How would you…")
- Avoid naming UI elements (don't say "click the Deploy button")
- Have a clear success condition the designer can observe
- Include 1–2 follow-up questions after the task ("What did you like or dislike? Was anything confusing?")

**Non-verbal observation prompt** (include for each task): Remind the designer to note hesitations, wrong clicks, re-reads, failed attempts, and emotional reactions. These won't appear in transcripts.

### Post-Test Recap Questions

Always include these five:
1. What did you like about this experience?
2. What did you dislike or find confusing?
3. What were you expecting to see that wasn't there?
4. What constraints would prevent you from using this in your role?
5. Is there anything else you'd like to share about your experience?

Add 1–2 feature-specific questions based on the objectives.

---

⚠️ **Present the full draft and ask for approval before continuing.** Invite the designer to adjust tasks, swap questions, or add persona-specific context before finalizing.

---

## Phase 3: Synthesis

This phase runs after tests are complete. The designer pastes in session notes (raw or lightly formatted) and you generate a structured findings report.

### Input

Ask the designer to share:
- Session notes for each participant (non-verbal notes are especially valuable — explain this if they haven't captured them)
- Any Gemini transcripts or AI-generated summaries they have

If notes are partial or sparse, note what's missing and work with what's available.

### Findings Report Structure

Generate the following sections:

**Summary**
2–3 sentences. Did the test meet its objectives? What was the headline finding?

**Key Quotes**
4–6 direct quotes with participant identifier. Choose quotes that explain value to devs and stakeholders — things that are surprising, validate a direction, or reveal a problem.

**Noteworthy**
Any single participant behavior that stood out — a task failure, an unexpected workaround, a strongly held opinion.

**Common Findings**
Break into three groups:
- **Common Failings** — tasks or flows where multiple participants struggled or failed
- **Common Confusion** — UI elements or copy that consistently caused hesitation or misinterpretation
- **Common Feedback** — recurring preferences, requests, or reactions (positive and negative)

For each finding, note how many participants shared it (e.g., "4 of 5 participants…").

**Action Items / Next Steps**
Bulleted list of concrete next steps. Tie each to a finding. Distinguish between "fix this before launch," "investigate further," and "log for later."

---

## Key Reminders (for designer reference)

**Do:**
- Encourage thinking aloud — reiterate if they go quiet
- Embrace silence — give participants time to read and process
- Note non-verbal behavior (hesitation, re-reads, wrong clicks)
- Include PMs and devs as observers when possible
- Lead the post-test analysis with your PM soon after

**Don't:**
- Explain the design or answer questions about usability decisions — instead ask: "What were you expecting?"
- Lead the participant with your questioning
- Defend your design choices
- Let sessions run over time
- Rely solely on transcripts for analysis — non-verbal context is critical

---

## Note on AI-Assisted Analysis

After sessions, consider using NotebookLM (or similar) by attaching:
- Gemini-generated session summaries + transcripts
- Your non-verbal session notes

Useful prompt: *"Generate a table of the most common feedback across all participants, with how many people said it, who said it, and when in the transcript."*
