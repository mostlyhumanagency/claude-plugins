# Researcher Subagent Prompt Template

Use this template when dispatching a research subagent for a specific skill unit.

```
Task tool (general-purpose):
  description: "Research [skill-name] for [topic]"
  prompt: |
    You are researching [knowledge area] to create a Claude Code skill.

    ## Topic Context

    [Brief description of the larger topic and where this unit fits]

    ## Sources (consult in this order)

    ### Official (authoritative)
    [Paste relevant official URLs from source manifest]

    ### Community (supplementary)
    [Paste relevant community URLs if needed]

    ## What to Extract

    1. **Core mental model** — 2-3 sentences explaining the concept
       so an agent can reason about when and why to use it

    2. **Key patterns** — For each major pattern:
       - What it solves
       - One excellent code example (complete, runnable, well-commented)
       - Common variations

    3. **Quick reference** — Scannable table of operations:
       | Operation | Syntax/API | Notes |
       |---|---|---|

    4. **Common mistakes** — Things that go wrong and how to fix:
       | Mistake | Symptom | Fix |
       |---|---|---|

    5. **When to use / not use** — Triggering conditions and boundaries

    ## Constraints

    - Official docs are authoritative — community sources supplement only
    - One great code example per pattern (not multi-language)
    - Note the source URL for every non-trivial fact
    - Code examples should be complete and runnable, not fragments
    - Skip content that duplicates other skill units: [list sibling units]
    - Target 1,500-2,000 words for core content (heavy reference separate)

    ## Output Format

    Return structured notes in this format:

    ### Mental Model
    [2-3 sentences]

    ### Patterns
    #### Pattern: [Name]
    [What it solves]
    ```[lang]
    [Complete code example]
    ```
    Source: [URL]

    ### Quick Reference
    | Operation | Syntax | Notes |
    |---|---|---|

    ### Common Mistakes
    | Mistake | Symptom | Fix |
    |---|---|---|

    ### When to Use
    - [triggering conditions]

    ### When NOT to Use
    - [boundaries]

    ### Sources Used
    - [URL] — [what was extracted]
```
