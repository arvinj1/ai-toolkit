# Storytelling Framework

## Overview
The Storytelling Framework skill applies a 7-step narrative structure to every presentation
(`.pptx`) and Jira artifact you create. It transforms flat, forgettable bullet-point content
into a compelling story that resonates with the audience.

## Description
Apply a 7-step storytelling framework to all presentations (.pptx) and Jira ticket/story/epic
creation. This skill ensures every deliverable follows a powerful narrative arc.

## Trigger Keywords
`presentation`, `deck`, `slides`, `pitch`, `Jira`, `ticket`, `story`, `epic`, `sprint`,
`user story`, `acceptance criteria`, `backlog item`

Even when the user does not explicitly mention storytelling, this framework is always applied
to structure content narratively.

## The 7 Steps

| # | Step | Core idea |
|---|------|-----------|
| 1 | **Introduce the Villain** | Open with the problem — make the audience feel it |
| 2 | **Position the Hero** | Reveal the solution as the turning point |
| 3 | **Add Personal Touches** | Anecdotes, quotes, and real data build trust |
| 4 | **Power of Three** | Break the narrative into exactly three key parts |
| 5 | **Visual Journey** | One idea per slide; clean formatting in Jira |
| 6 | **End With Impact** | Close with a call to action, not a generic "Thank You" |
| 7 | **Rehearse** | Speaker notes that sound like natural speech |

## For Presentations (.pptx)

1. **Opening slide(s):** Name the problem. Make the audience feel the pain.
2. **Solution slide(s):** Introduce the hero solution. Make it aspirational.
3. **Evidence/Story slide(s):** Anecdotes, quotes, real data.
4. **Core structure:** Three key messages or pillars.
5. **Visual design:** One idea per slide, minimal text.
6. **Closing slide:** Powerful call to action — never a generic "Thank You."
7. **Speaker notes:** Natural, conversational language.

## For Jira Tickets / Stories / Epics

Every Jira artifact uses this template:

```markdown
## The Problem (The Villain)
[Describe the pain point. Be specific. Who is affected and how?]

## The Solution (The Hero)
[Describe what we're building and why it's the right answer.]

## Context & Background (Personal Touches)
[Why does this matter? Any user feedback, support tickets, or anecdotes?]

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

## General Principles
- Always lead with **WHY** before **WHAT**.
- Make the audience or reader care before giving them details.
- Structure content as a narrative arc, not a flat list.
- Every deliverable should answer: *What's the problem? What's the solution? Why should I care?*

## Suite
This skill is part of the **intentforge** suite. Install the suite to activate it:

```bash
./install/install.sh intentforge --target user
# or for a specific project:
./install/install.sh intentforge --target project --project-root /path/to/repo
```
