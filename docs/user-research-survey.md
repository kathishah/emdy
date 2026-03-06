# Emdy — Foundational user research survey

**Goal:** Validate whether reading Markdown files is a real pain point, understand who experiences it, how they currently deal with it, and where the problem happens.

**Target:** Broad distribution across technical and non-technical populations. ~2 minutes to complete.

**Distribution channels:** TBD (Reddit, LinkedIn, Slack/Discord communities, personal network, Twitter/X)

---

## Survey questions

### Q1. What best describes your role?

_Single select_

- Software engineer / developer
- Designer (product, UX, graphic)
- Product manager
- Project manager / program manager
- Marketing / communications
- Operations / business analyst
- Executive / leadership
- Researcher / data scientist
- Writer / editor / content
- Student
- Other: ___________

### Q2. Which of these tools do you use regularly?

_Multi-select_

- Google Docs / Microsoft Word
- Notion / Confluence
- Slack / Teams
- GitHub / GitLab
- VS Code / Sublime / other code editor
- Terminal / command line
- Figma / Sketch
- Obsidian / Logseq / other note-taking app
- AI tools (ChatGPT, Claude, Copilot, etc.)

### Q3. Do you know what a Markdown file is?

_Single select_

- Yes, I work with them regularly
- Yes, I know what they are but don't work with them often
- I've heard of Markdown but I'm not sure what it is
- No

_If "No" → skip to Q10 (end screen with thank-you message). This isn't a filter for quality — it just means the remaining questions won't make sense for this respondent._

### Q4. How often do you encounter Markdown files (`.md`)?

_Single select_

- Daily
- A few times a week
- A few times a month
- Rarely (a few times a year)
- Never

_If "Rarely" or "Never" → skip to Q10._

### Q5. How do you typically encounter Markdown files?

_Multi-select_

- I receive them from colleagues or collaborators
- I create them myself by hand
- AI tools generate them for me (ChatGPT, Claude, Copilot, etc.)
- I find them in project repos or documentation (READMEs, wikis, etc.)
- I edit Markdown files that others created
- Other: ___________

### Q6. What kinds of Markdown files do you read?

_Multi-select_

- READMEs and project documentation
- Meeting notes or summaries
- Personal notes or journals
- PRDs or product specs
- Technical specs or architecture docs
- Blog posts or articles
- Runbooks or how-to guides
- AI-generated outputs (reports, outlines, drafts)
- Changelogs or release notes
- Other: ___________

### Q7. When you need to read a Markdown file, what do you usually do?

_Multi-select_

- Open it in a code editor (VS Code, Sublime, etc.)
- Open it in a Markdown editor (Typora, Obsidian, iA Writer, etc.)
- View it on GitHub or GitLab in a browser
- Open it in TextEdit / Notepad (see raw text)
- Use a Quick Look extension on macOS
- Paste it into an online Markdown viewer
- Ask the sender to convert it to PDF or another format
- Read the raw Markdown as-is
- Other: ___________

### Q8. What frustrates you about reading Markdown files today?

_Multi-select_

- I see raw syntax instead of formatted text
- I have to open a heavy app just to read a document
- Tables and complex formatting look broken or unreadable
- Images don't display properly
- I can't easily copy formatted text into other apps (email, Docs, Slack)
- There's no good way to read them on my phone
- I have to ask someone to convert the file for me
- It takes too many steps to just read the content
- I don't have any frustrations — it works fine for me
- Other: ___________

### Q9. If you had a dedicated Markdown reader, which features would matter most to you?

_Multi-select_

- Clean formatted view (no raw syntax)
- Dark mode
- Search within a document
- Copy formatted text into other apps
- Export to PDF
- Side-by-side view of multiple files
- Share a rendered link with someone else
- Comment or annotate
- Collaborate with others in real time
- Auto-refresh when the file changes on disk
- Quick Look preview in Finder (press Space to preview)
- Other: ___________

### Q10. Is there anything you wish you could do with Markdown files that you currently can't?

_Open text (optional)_

### Q11. Thank you!

Thanks for taking the time. Your responses help us understand how people actually work with Markdown files today.

---

## Design notes

### What each question tells us

| Question | Research objective |
|----------|-------------------|
| Q1 (role) | Audience segmentation — who has this problem? |
| Q2 (tools) | Technical literacy signal — behavioral, not self-reported |
| Q3 (know Markdown?) | Screener — also tells us what % of a general population even recognizes the term |
| Q4 (frequency) | Problem scale — is this a daily reality or a rare occurrence? |
| Q5 (how encounter) | Relationship to Markdown — reader, creator, editor, or AI-assisted? Feeds audience definition |
| Q6 (content types) | What Markdown is used for — reveals use cases, content complexity, and whether the reader needs to handle tables, code blocks, images, etc. |
| Q7 (current behavior) | Workarounds — what are the competitive alternatives? What's "good enough" today? |
| Q8 (frustrations) | Pain points — what specifically is broken? Validates or challenges desk research findings |
| Q9 (desired features) | Feature validation — which capabilities matter most? Surfaces demand for collaboration, sharing, annotation beyond basic reading |
| Q10 (wish) | Open discovery — surfaces unmet needs we haven't considered (collaboration, commenting, etc.) |

### Analysis plan

- **Cross-tabulate Q1 × Q4 × Q8** to see which roles experience the problem most frequently and most painfully
- **Cross-tabulate Q1 × Q6** to see which roles read which content types — reveals whether non-technical users encounter different Markdown than developers
- **Cross-tabulate Q5 × Q8** to see if people who receive Markdown have different frustrations than people who create it
- **Cross-tabulate Q2 × Q7** to see how technical literacy correlates with workaround sophistication
- **Cross-tabulate Q1 × Q9** to see which features matter to which roles — are non-technical users asking for different things than developers?
- **Q9 feature frequency** to rank features by demand and identify potential killer features (especially collaboration, sharing, annotation)
- **Q10 open responses** get coded for themes, especially anything related to collaboration, sharing, commenting, or cross-platform needs
- **Q3 "No" response rate** tells us how large the population is that encounters `.md` files without even knowing what they are — this has implications for how we market the product
