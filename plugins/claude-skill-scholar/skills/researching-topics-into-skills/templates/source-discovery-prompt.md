# Source Discovery Subagent Prompt Template

Use this template when dispatching a subagent to discover and validate sources for a topic.

```
Task tool (general-purpose):
  description: "Discover sources for [topic]"
  prompt: |
    Find and validate documentation sources for [topic].

    ## Step 1: Find the Official Domain

    Search for "[topic] official documentation" to identify the canonical domain.

    ## Step 2: Check llms.txt

    Fetch these URLs (use WebFetch):
    - https://[domain]/llms.txt
    - https://[domain]/llms-full.txt
    - https://[domain]/.well-known/llms.txt

    If found, parse for:
    - Documentation structure and sections
    - Key page URLs
    - Recommended reading order

    ## Step 3: Official Documentation

    Identify and validate:
    - Main documentation site URL
    - API reference URL (if separate)
    - Getting started / tutorial URL
    - GitHub repository URL
    - Official blog or changelog URL
    - Current stable version

    For each URL, fetch and confirm it loads and is current.

    ## Step 4: Community Sources (only if official docs have gaps)

    Search for supplementary sources ONLY for areas official docs don't cover well:
    - "[topic] best practices [current year]"
    - "[topic] common mistakes"
    - "awesome [topic]" site:github.com

    Validate each community source:
    - Published within current major version era
    - Author is known/reputable (conference speaker, core team, recognized expert)
    - High engagement (stars, upvotes, shares)
    - Not AI-generated or SEO-farmed content

    ## Step 5: Build Topic Structure

    From llms.txt (if found) and docs table of contents, extract:
    - Major sections/areas of the topic
    - Natural groupings of concepts
    - Dependencies between areas (what must be learned first)

    ## Output Format

    ### Source Manifest

    #### Official
    - llms.txt: [URL] — [found/not found, summary of contents if found]
    - Docs: [URL] — [current version, main sections]
    - API ref: [URL or "included in docs"]
    - Repo: [URL] — [stars, last updated]
    - Blog/changelog: [URL]

    #### Community (if needed)
    - [Title] by [Author]: [URL] — [why trusted, what it covers that docs don't]

    ### Topic Structure (from docs)
    [Outline of major areas with brief descriptions]

    ### Suggested Learning Order
    [Areas ordered by dependency — fundamentals first]

    ### Gaps Identified
    [Areas where official docs are weak or missing, community sources needed]
```
