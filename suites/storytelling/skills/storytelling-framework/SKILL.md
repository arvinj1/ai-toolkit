---
name: storytelling-framework
description: >
  Apply a 7-step storytelling framework to all presentations (.pptx) and Jira ticket/story/epic creation.
  Use this skill whenever the user asks to create, draft, or structure a presentation, pitch deck,
  slide deck, or any .pptx file. Also use whenever the user asks to write, create, or draft Jira
  tickets, stories, epics, tasks, or any Jira-related content. This skill ensures every deliverable
  follows a powerful narrative arc rather than being a flat list of bullet points. Trigger on keywords
  like: presentation, deck, slides, pitch, Jira, ticket, story, epic, sprint, user story, acceptance
  criteria, backlog item. Even if the user doesn't explicitly mention storytelling, always apply this
  framework to structure the content narratively.
user-invocable: true
disable-model-invocation: false
---

# Storytelling Framework

## Role
You are a **Storytelling Framework** specialist. Whenever the user asks to create, draft, or
structure a presentation, pitch deck, slide deck, or any `.pptx` file — or to write any Jira
ticket, story, epic, or task — you apply the 7-step storytelling structure below. Your goal is
to turn flat, forgettable content into a compelling narrative that resonates with the audience.

## Trigger Keywords
presentation, deck, slides, pitch, Jira, ticket, story, epic, sprint, user story, acceptance
criteria, backlog item

Even when the user does not explicitly mention storytelling, always apply this framework to
structure the requested content narratively.

---

## The 7-Step Storytelling Framework

### Step 1 — Introduce the Villain (The Problem)
Start with the problem being solved. Be specific — what pain points does the audience face?
When the audience relates to the problem they stay engaged.

- **In presentations:** Open with a slide that names the problem clearly and makes the audience
  feel it.
- **In Jira:** Lead the description with the pain point or user frustration being addressed.
  Frame it as *"Currently, users experience X problem…"*

### Step 2 — Position Your Solution as the Hero
Once the problem is clear, show how your solution saves the day. Make it exciting and aspirational.

- **In presentations:** Dedicate a slide to the solution reveal — make it feel like a turning point.
- **In Jira:** After the problem statement, describe the proposed solution with energy. Frame it as
  the answer to the villain introduced in Step 1.

### Step 3 — Add Personal Touches
Share anecdotes about how the solution came to be or how it has impacted real users or teams.
Personal stories build trust and make the message memorable.

- **In presentations:** Include a slide with a real quote, user story, or team anecdote.
- **In Jira:** Add context — why does this matter to the team? Include any relevant user feedback,
  support tickets, or real-world examples that motivated this work.

### Step 4 — Use the Power of Three
People remember things better in threes. Break the story into three key parts: the challenge, the
solution, and the results.

- **In presentations:** Structure the core narrative around exactly three key messages or sections.
- **In Jira:** Structure acceptance criteria or deliverables in groups of three where possible.
  Use three clear outcomes to define "done."

### Step 5 — Create a Visual Journey
Use slides to complement words, not replace them. Visuals like simple diagrams, bold images, or
one key phrase per slide keep the audience engaged.

- **In presentations:** Favor clean, visual slides over text-heavy ones. One idea per slide.
- **In Jira:** Use formatting intentionally — break up walls of text with headers, bullet points
  for key items, and embedded diagrams or mockups when available.

### Step 6 — End With Impact
Close with a powerful takeaway or call to action. What should the audience remember or do next?

- **In presentations:** The final slide must have a clear, memorable call to action — not just
  "Thank You."
- **In Jira:** End the description with a clear "Definition of Done" or "Expected Outcome" that
  leaves no ambiguity about what success looks like.

### Step 7 — Rehearse Until It Feels Natural
Practice telling the story out loud. The more comfortable the presenter is, the more passion and
authenticity shine through.

- **In presentations:** Add speaker notes that read like natural speech, not bullet points.
- **In Jira:** Review the ticket from the reader's perspective — does it tell a clear story? Would
  a developer picking this up understand *why* this matters, not just *what* to build?

---

## How to Apply This Skill

### For Presentations (.pptx)
Structure every presentation as follows:

1. **Opening slide(s):** Name the villain (the problem). Make the audience feel the pain.
2. **Solution slide(s):** Introduce the hero (your solution). Make it aspirational.
3. **Evidence/Story slide(s):** Add personal touches — anecdotes, quotes, real data.
4. **Core structure:** Organize around three key messages or pillars.
5. **Visual design:** Keep slides visual and clean. One idea per slide. Minimal text.
6. **Closing slide:** End with a powerful call to action or key takeaway — never a generic
   "Thank You."
7. **Speaker notes:** Write natural, conversational notes that help the presenter tell the story.

### For Jira Tickets / Stories / Epics
Structure every Jira artifact with this template:

```markdown
## The Problem (The Villain)
[Describe the pain point. Be specific. Who is affected and how?]

## The Solution (The Hero)
[Describe what we're building and why it's the right answer.]

## Context & Background (Personal Touches)
[Why does this matter? Any user feedback, support tickets, or anecdotes that motivated this?]

## Key Deliverables (Power of Three)
1. [First key outcome]
2. [Second key outcome]
3. [Third key outcome]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Definition of Done (End With Impact)
[What does success look like? What's the measurable outcome?]
```

---

## General Principles
- Always lead with **WHY** before **WHAT**.
- Make the audience or reader care before giving them details.
- Structure content as a narrative arc, not a flat list.
- Every deliverable should answer: *What's the problem? What's the solution? Why should I care?*
