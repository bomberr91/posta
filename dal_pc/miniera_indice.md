# Indice automatico della miniera — 01/11 12:07
TOTALE PEZZI INDICIZZATI: 180

| ./.[CHIAVE-RIMOSSA].md | blueprint-figure | > |
| ./.[CHIAVE-RIMOSSA].md | Checks a figure must pass | Each check below has a rule name and a test that a script or a reviewer can run on the SVG file. Inside the AI Engineering from Scratch repo, `scripts/audit_man |
| ./.[CHIAVE-RIMOSSA].md | Figure grammar: tokens, hues, arrows, sizes | This file holds the exact values that a figure uses. The sibling skill `course-style` holds the full course tokens. The values below are copied here so this ski |
| ./.[CHIAVE-RIMOSSA].md | The nine figure kinds | Each figure has one kind. Pick the kind from the claim, then use the layout below. All coordinates are in viewBox units at width 640. Keep content between x 20  |
| ./.[CHIAVE-RIMOSSA].md | build-project | > |
| ./.[CHIAVE-RIMOSSA].md | check-understanding | Phase quiz for AI Engineering from Scratch. Trigger with "quiz me", "test phase", "check my understanding", "do I know phase 3", or `/check-understanding <phase |
| ./.[CHIAVE-RIMOSSA].md | claude-certification | > |
| ./.[CHIAVE-RIMOSSA].md | course-guide | > |
| ./.[CHIAVE-RIMOSSA].md | course-style | > |
| ./.[CHIAVE-RIMOSSA].md | Accessibility and reduced motion | These defaults apply to every page, card, and figure in the course. Each one is a value or a markup rule that you can check in the output. |
| ./.[CHIAVE-RIMOSSA].md | Labels and layout | Course figures for lessons, the README, and the home page use one global number. |
| ./.[CHIAVE-RIMOSSA].md | Plain technical English | Course prose follows a short set of rules taken from Simplified Technical English. Each rule is a test that a reviewer or a script can run on the text. The manu |
| ./.[CHIAVE-RIMOSSA].md | Tokens | The course has two token sets. Pages and site components use the site tokens. Static manual figures use the `--m-` figure tokens, so a figure renders the same i |
| ./.[CHIAVE-RIMOSSA].md | Typography | The course uses three families. The display face is a pixel font for headings. The serif carries reading text. The mono carries labels, meta lines, figure text, |
| ./.[CHIAVE-RIMOSSA].md | find-your-level | > |
| ./.[CHIAVE-RIMOSSA].md | Placement Quiz Answer Key | Read only the round the learner has just completed. Keep later rounds out of |
| ./.[CHIAVE-RIMOSSA].md | isometric-explainer | > |
| ./.[CHIAVE-RIMOSSA].md | Colour and ink | This is the look for every machine page. Colour shows what each part is made of. Ink shows its shape. The motion and the model stay the same. Only the paint cha |
| ./.[CHIAVE-RIMOSSA].md | Invent the machine | Each part of the machine does one step of the process. After one run, a reader can explain the process without the captions. |
| ./.[CHIAVE-RIMOSSA].md | Geometry | All geometry is built once in Node by the build script. The browser only moves groups, toggles their visibility and rebuilds a few paths. |
| ./.[CHIAVE-RIMOSSA].md | The live script | The build script inlines the kit, the model, a data object `D` and the live script into one `<script>`. The live script turns model events into motion and keeps |
| ./.[CHIAVE-RIMOSSA].md | The state model | The model is a plain ES module with no DOM, no timers and no randomness. The build script inlines it into the page, and the tests import it directly. Everything |
| ./.[CHIAVE-RIMOSSA].md | Verification loop | Do not trust the code. Look at the pixels. Run this loop after each build, and fix every finding before the next run. |
| ./.claude/skills/learn/SKILL.md | learn | > |
| ./.[CHIAVE-RIMOSSA].md | learn-agent-skills | > |
| ./.claude/skills/learn-mcp/SKILL.md | learn-mcp | > |
| ./.[CHIAVE-RIMOSSA].md | learn-reverse-engineering | > |
| ./.[CHIAVE-RIMOSSA].md | lesson-screen | > |
| ./.[CHIAVE-RIMOSSA].md | Build a figure on the fly | A built figure is one page that a tutor makes for one lesson while the lesson runs. This page holds the stages of a build, the contract that every built page fo |
| ./.[CHIAVE-RIMOSSA].md | Hosts | The lesson screen needs three things: Node.js 20 or later, a local port, and a browser on the learner's machine. This page lists the cases and what to do in eac |
| ./.[CHIAVE-RIMOSSA].md | Screens | A screen is one HTML file in the screens folder. The browser shows the newest file. Write one file per step. |
| ./.[CHIAVE-RIMOSSA].md | mcpa-certification | > |
| ./.[CHIAVE-RIMOSSA].md | motion-figure | > |
| ./.[CHIAVE-RIMOSSA].md | Dither fields | A dither field is a band of moving pixels drawn with ordered dithering. It uses only three colours from the page: the paper, the accent, and the ink. Use one as |
| ./.[CHIAVE-RIMOSSA].md | Mechanism figures | A mechanism figure is a small interactive panel that shows how one system works. The reader drives it with one control, watches the named contents change, and r |
| ./.[CHIAVE-RIMOSSA].md | SMIL rules for animated lesson figures | This file holds the twelve rules in full, then one note for each rule, then a validator. The rules are facts that real figures on the course site proved. A figu |
| ./.[CHIAVE-RIMOSSA].md | Tokens for motion figures | These values come from the course stylesheet. The sibling skill `course-style` holds the full set. This file copies only what a motion figure needs, so this ski |
| ./.[CHIAVE-RIMOSSA].md | The LF toolkit and two complete examples | The course runtime puts one object on the page: `window.LF`. Figure modules use it to build DOM and SVG nodes, to make controls, and to register figures by name |
| ./.[CHIAVE-RIMOSSA].md | start-learning | > |
| ./.[CHIAVE-RIMOSSA].md | write-manual | > |
| ./.[CHIAVE-RIMOSSA].md | The audit | The audit reads every document, figure, listing, and quote of a manual, and prints one line per finding. It ends with `TOTAL <n>` and a count per rule. A manual |
| ./.[CHIAVE-RIMOSSA].md | The capture kit | Every request, response, and event that a manual shows comes from a run. The capture kit is the program that makes those runs and writes them to files. Listings |
| ./.[CHIAVE-RIMOSSA].md | manual.json | `manual.json` is the manifest of one manual. It holds the identity, the pin, the palette, the ranked sources, and the order of parts and sections. The build val |
| ./.[CHIAVE-RIMOSSA].md | Prose rules | A manual uses limits from Simplified Technical English. The audit checks each limit on every prose span: paragraphs, list items, table cells, takeaways, figure  |
| ./.[CHIAVE-RIMOSSA].md | Research, sources, and the conflict register | A manual makes no claim that you cannot trace to a ranked source. Do the research before you write the first section, and keep it in files beside the manual. |
| ./.[CHIAVE-RIMOSSA].md | Section template | Copy this skeleton into `sections/<n>-<m>-<slug>.md`. Replace every value. Keep the order of the blocks. |
| .[CHIAVE-RIMOSSA].md | Turn a Request Into a Testable Contract | > A strong prompt does not merely describe what to write. It makes success observable before generation begins. |
| .[CHIAVE-RIMOSSA].md | Claude Code Memory, Rules, Skills, and CI | > Put stable guidance where its scope is true, and executable constraints where failure is unacceptable. |
| .[CHIAVE-RIMOSSA].md | Configuration Scope Audit: Python Service | The root guide contains purpose, layout, canonical commands, security boundary, |
| .[CHIAVE-RIMOSSA].md | migration-review | Review database migration files when a change adds or modifies paths under migrations/. Use it before merge to collect forward, rollback, locking, and data-safe |
| .[CHIAVE-RIMOSSA].md | Migration Review Checklist | - Identify the schema and data transition. |
| .[CHIAVE-RIMOSSA].md | Prompt Templates and Argument Completion | > A prompt is a template the server writes and the user chooses to run. Nothing about it should surprise the person who picked it. |
| .[CHIAVE-RIMOSSA].md | Prompt and Completion Reference | A one-page reference for the MCPA "Interactions and Execution" domain, aligned to MCP 2026-07-28. |
| .[CHIAVE-RIMOSSA].md | Prompt Engineering: Techniques & Patterns | > Most people write prompts like they are texting a friend. Then they wonder why a 200-billion parameter model gives mediocre answers. Prompt engineering is not |
| .[CHIAVE-RIMOSSA].md | prompt-prompt-optimizer | Takes a draft prompt and rewrites it using proven prompt engineering patterns for maximum effectiveness across models |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA] | [CHIAVE-RIMOSSA] | Decision framework for choosing the right prompt pattern based on task type, reliability requirements, and target model |
| .[CHIAVE-RIMOSSA].md | Prompt Caching and Context Caching | > Your system prompt is 4,000 tokens. Your RAG context is 20,000 tokens. You send both with every request. You also pay for both — every time. Prompt caching le |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA] | prompt-caching-planner | Design a cache-friendly prompt layout and pick the right provider caching mode. |
| .[CHIAVE-RIMOSSA].md | MCP Resources and Prompts: Addressable Context for Stateless | > Tools perform operations. Resources expose addressable content. Prompts package user-selected message templates. A good MCP server keeps those contracts separ |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA] | primitive-splitter | Review an MCP server design and separate tools, resources, prompts, caching, and subscriptions using the 2026-07-28 contract. |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/docs/en.md | Agent Skills: Portable Contract and Runtime Boundary | > A skill is not a long prompt with a better filename. It is a discoverable package of instructions, resources, and executable helpers that enters an agent's co |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/SKILL.md | [CHIAVE-RIMOSSA] | Validate an Agent Skill package and choose the right instruction, capability, or lifecycle primitive before implementation. |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/references/contract.md | Portable contract checklist | - The bundle is a directory containing a regular `SKILL.md` file. |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/references/decision-model.md | Primitive decision model | Select by responsibility. More than one primitive may be correct. |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/docs/en.md | Skill Discovery and Progressive Disclosure | > A skill becomes useful before its body is loaded. Its name and description earn a place in the catalog; its deeper files earn context only when the task reach |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/SKILL.md | [CHIAVE-RIMOSSA] | Build a bounded Agent Skill catalog across explicit discovery scopes and report collisions before loading instruction bodies. |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/references/discovery-contract.md | Discovery contract | Discovery has three disclosure levels: |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/docs/en.md | Skill Invocation and Routing | > Invocation is an authority decision followed by a relevance decision. A good description helps the model choose; a good policy decides whether that choice is  |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/SKILL.md | [CHIAVE-RIMOSSA] | Design and test explicit human, implicit model or agent, programmatic application, bounded [CHIAVE-RIMOSSA], and harness activation policies for an Agent Skill |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/references/invocation-model.md | Invocation model | | Channel | Initiator | Selection | Typical use | |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/docs/en.md | Skill Permissions, Sandboxes, and Trust | > A skill can suggest an action. Only the host can authorize it, only an isolation boundary can contain it, and only verification can tell you whether it worked |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/SKILL.md | [CHIAVE-RIMOSSA] | Review a [CHIAVE-RIMOSSA] filesystem, command, network, secret, or destructive action against an explicit sandbox policy without executing it. |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/references/threat-model.md | Threat model | Review these boundaries independently: |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/docs/en.md | Skill Evals, Packaging, and Portability | > A skill is finished when its package survives linting, routes on the right requests, improves a measured task, stays inside policy, and degrades honestly on a |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/SKILL.md | [CHIAVE-RIMOSSA] | Evaluate an Agent Skill bundle for structural integrity, trigger quality, artifact improvement, script correctness, safety, installed-tree integrity, and target |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA]/references/eval-contract.md | Evaluation contract | A release candidate passes only when all required surfaces pass: |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/docs/en.md | Skill Libraries and Lifelong Learning (Voyager) | > Voyager (Wang et al., TMLR 2024) treats executable code as a skill. Skills are named, retrievable, composable, and refined by environment feedback. This is th |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA]/outputs/[CHIAVE-RIMOSSA] | skill-library | Generate a Voyager-shaped skill library with registration, retrieval by similarity, compositional execution, and failure-driven refinement. |
| .[CHIAVE-RIMOSSA].md | Prompt Injection and the PVE Defense | > Greshake et al. (AISec 2023) established indirect prompt injection as the defining agent security problem. Attacker plants instructions in data the agent retr |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA] | injection-defense | Build a PVE (Prompt-Validator-Executor) layer with source-tagged content, injection-marker scanning, and allowlist navigation for any agent runtime. |
| .[CHIAVE-RIMOSSA].md | Prompt Caching and Semantic Caching Economics | > **Pricing snapshot dated 2026-04.** Numeric claims below reflect vendor rate cards captured at this lesson's publication; verify against the linked docs befor |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA] | cache-auditor | Audit an LLM prompt template and traffic pattern for cacheability. Recommend prompt restructure, TTL choice, parallelization fix, and semantic-cache threshold. |
| .[CHIAVE-RIMOSSA].md | Indirect Prompt Injection — Production Attack Surface | > Indirect prompt injection (IPI) embeds instructions inside external content — a web page, an email, a shared document, a support ticket — consumed by an agent |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA] | ipi-audit | Audit an agentic deployment for indirect prompt injection exposure and information-flow-control coverage. |
| .[CHIAVE-RIMOSSA].md | Capstone 83 — Prompt Injection Detector | > A detector is a function from prompt to confidence and category. Anything else is a vibe. |
| .[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA] | [CHIAVE-RIMOSSA] | Layered detector pipeline that returns a category and confidence for any prompt, with measurable precision and recall |
| .[CHIAVE-RIMOSSA].md | Prompt Regression Tester | A prompt-change review kit that identifies exactly which user commitments broke. |
| .[CHIAVE-RIMOSSA].md | Validate cases before scoring | **Stage 1 of 4.** Python. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | Score recorded outputs without a model | **Stage 2 of 4.** Python. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | starter | Continue editing main.py in the workspace created at stage 1. |
| .[CHIAVE-RIMOSSA].md | Compare the same cases across revisions | **Stage 3 of 4.** Python. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | starter | Continue editing main.py in the workspace created at stage 1. |
| .[CHIAVE-RIMOSSA].md | Gate releases on explicit tolerances | **Stage 4 of 4.** Python. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | starter | Continue editing main.py in the workspace created at stage 1. |
| .[CHIAVE-RIMOSSA].md | Self-Improving Skill Loop | A correction-to-skill experiment runner preserving sources, preventing leakage and supporting rollback. |
| .[CHIAVE-RIMOSSA].md | Split labeled cases without identity leakage | **Stage 1 of 4.** Python. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | Execute and score a transparent routing skill | **Stage 2 of 4.** Python. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | Propose rules from development errors only | **Stage 3 of 4.** Python. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | Require a separate gate before promotion | **Stage 4 of 4.** Python. Plan about 2 hours. |
| ./projects/[CHIAVE-RIMOSSA]/README.md | Cross-Agent Skill Installer | A cross-agent upgrade tool promising a reviewable diff and no lost local edits. |
| ./projects/[CHIAVE-RIMOSSA]/stages/01-bundle/docs/en.md | Validate a portable bundle | **Stage 1 of 4.** Typescript. Plan about 2 hours. |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | starter | Implement stage 1: Validate a portable bundle. Keep earlier behavior passing. |
| ./projects/[CHIAVE-RIMOSSA]/stages/02-translate/docs/en.md | Translate metadata and hash content | **Stage 2 of 4.** Typescript. Plan about 2 hours. |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | starter | Implement stage 2: Translate metadata and hash content. Keep earlier behavior passing. |
| ./projects/[CHIAVE-RIMOSSA]/stages/03-install/docs/en.md | Install atomically within a root | **Stage 3 of 4.** Typescript. Plan about 2 hours. |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | starter | Implement stage 3: Install atomically within a root. Keep earlier behavior passing. |
| ./projects/[CHIAVE-RIMOSSA]/stages/04-upgrades/docs/en.md | Protect edits during upgrades | **Stage 4 of 4.** Typescript. Plan about 2 hours. |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | starter | Implement stage 4: Protect edits during upgrades. Keep earlier behavior passing. |
| ./projects/skill-router/README.md | Skill Router | A routing debugger showing why the wrong skill activated and how to fix a rule. |
| .[CHIAVE-RIMOSSA].md | "check-tests" | "Run the local test evidence check" |
| .[CHIAVE-RIMOSSA].md | "release-publish" | "Publish an approved Orchard release" |
| .[CHIAVE-RIMOSSA].md | "release-review" | "Review Orchard deployment manifests" |
| .[CHIAVE-RIMOSSA].md | Parse a typed skill catalog | **Stage 1 of 4.** Typescript. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | starter | Implement stage 1: Parse a typed skill catalog. Keep earlier behavior passing. |
| .[CHIAVE-RIMOSSA].md | Score words and repository paths | **Stage 2 of 4.** Typescript. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | starter | Implement stage 2: Score words and repository paths. Keep earlier behavior passing. |
| .[CHIAVE-RIMOSSA].md | Resolve dependencies before execution | **Stage 3 of 4.** Typescript. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | starter | Implement stage 3: Resolve dependencies before execution. Keep earlier behavior passing. |
| .[CHIAVE-RIMOSSA].md | Abstain on ambiguous or blocked requests | **Stage 4 of 4.** Typescript. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | starter | Implement stage 4: Abstain on ambiguous or blocked requests. Keep earlier behavior passing. |
| ./projects/skill-scanner/README.md | Skill Supply-Chain Scanner | A skill-change review assistant quoting newly introduced capabilities. |
| .[CHIAVE-RIMOSSA].md | orchard-review | Review a release proposal |
| .[CHIAVE-RIMOSSA].md | orchard-review | Review a release proposal |
| .[CHIAVE-RIMOSSA].md | Retain byte-accurate source spans | **Stage 1 of 4.** Rust. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | Detect named advisory patterns | **Stage 2 of 4.** Rust. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | Score distinct evidence without inflation | **Stage 3 of 4.** Rust. Plan about 2 hours. |
| .[CHIAVE-RIMOSSA].md | Build an explicit review gate | **Stage 4 of 4.** Rust. Plan about 2 hours. |
| ./projects/[CHIAVE-RIMOSSA]/README.md | SKILL.md Validator and Loader | A compatibility linter explaining why a skill works in one agent but fails in another. |
| ./projects/[CHIAVE-RIMOSSA]/examples/orchard-release/SKILL.md | "orchard-release" | "Check deployment evidence and recovery conditions." |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | references | The Orchard restore rehearsal finished at 09:20 UTC with two verified records. |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | Parse an explicit frontmatter subset | "Check \"replicas\" first" |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | Validate names and descriptions | **Stage 2 of 4.** Rust. Plan about 2 hours. |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | Contain resource paths | **Stage 3 of 4.** Rust. Plan about 2 hours. |
| ./projects/[CHIAVE-RIMOSSA][CHIAVE-RIMOSSA].md | Load context within a character budget | **Stage 4 of 4.** Rust. Plan about 2 hours. |
| ./skills/blueprint-figure/SKILL.md | blueprint-figure | > |
| .[CHIAVE-RIMOSSA].md | Checks a figure must pass | Each check below has a rule name and a test that a script or a reviewer can run on the SVG file. Inside the AI Engineering from Scratch repo, `scripts/audit_man |
| .[CHIAVE-RIMOSSA].md | Figure grammar: tokens, hues, arrows, sizes | This file holds the exact values that a figure uses. The sibling skill `course-style` holds the full course tokens. The values below are copied here so this ski |
| .[CHIAVE-RIMOSSA].md | The nine figure kinds | Each figure has one kind. Pick the kind from the claim, then use the layout below. All coordinates are in viewBox units at width 640. Keep content between x 20  |
| ./skills/build-project/SKILL.md | build-project | > |
| .[CHIAVE-RIMOSSA].md | check-understanding | Phase quiz for AI Engineering from Scratch. Trigger with "quiz me", "test phase", "check my understanding", "do I know phase 3", or `/check-understanding <phase |
| .[CHIAVE-RIMOSSA].md | claude-certification | > |
| ./skills/course-guide/SKILL.md | course-guide | > |
| ./skills/course-style/SKILL.md | course-style | > |
| .[CHIAVE-RIMOSSA].md | Accessibility and reduced motion | These defaults apply to every page, card, and figure in the course. Each one is a value or a markup rule that you can check in the output. |
| .[CHIAVE-RIMOSSA].md | Labels and layout | Course figures for lessons, the README, and the home page use one global number. |
| .[CHIAVE-RIMOSSA].md | Plain technical English | Course prose follows a short set of rules taken from Simplified Technical English. Each rule is a test that a reviewer or a script can run on the text. The manu |
| .[CHIAVE-RIMOSSA].md | Tokens | The course has two token sets. Pages and site components use the site tokens. Static manual figures use the `--m-` figure tokens, so a figure renders the same i |
| .[CHIAVE-RIMOSSA].md | Typography | The course uses three families. The display face is a pixel font for headings. The serif carries reading text. The mono carries labels, meta lines, figure text, |
| ./skills/find-your-level/SKILL.md | find-your-level | > |
| .[CHIAVE-RIMOSSA].md | Placement Quiz Answer Key | Read only the round the learner has just completed. Keep later rounds out of |
| .[CHIAVE-RIMOSSA].md | isometric-explainer | > |
| .[CHIAVE-RIMOSSA].md | Colour and ink | This is the look for every machine page. Colour shows what each part is made of. Ink shows its shape. The motion and the model stay the same. Only the paint cha |
| .[CHIAVE-RIMOSSA].md | Invent the machine | Each part of the machine does one step of the process. After one run, a reader can explain the process without the captions. |
| .[CHIAVE-RIMOSSA].md | Geometry | All geometry is built once in Node by the build script. The browser only moves groups, toggles their visibility and rebuilds a few paths. |
| .[CHIAVE-RIMOSSA].md | The live script | The build script inlines the kit, the model, a data object `D` and the live script into one `<script>`. The live script turns model events into motion and keeps |
| .[CHIAVE-RIMOSSA].md | The state model | The model is a plain ES module with no DOM, no timers and no randomness. The build script inlines it into the page, and the tests import it directly. Everything |
| .[CHIAVE-RIMOSSA].md | Verification loop | Do not trust the code. Look at the pixels. Run this loop after each build, and fix every finding before the next run. |
| ./skills/learn/SKILL.md | learn | > |
| .[CHIAVE-RIMOSSA].md | learn-agent-skills | > |
| ./skills/learn-mcp/SKILL.md | learn-mcp | > |
| .[CHIAVE-RIMOSSA].md | learn-reverse-engineering | > |
| ./skills/lesson-screen/SKILL.md | lesson-screen | > |
| .[CHIAVE-RIMOSSA].md | Build a figure on the fly | A built figure is one page that a tutor makes for one lesson while the lesson runs. This page holds the stages of a build, the contract that every built page fo |
| .[CHIAVE-RIMOSSA].md | Hosts | The lesson screen needs three things: Node.js 20 or later, a local port, and a browser on the learner's machine. This page lists the cases and what to do in eac |
| .[CHIAVE-RIMOSSA].md | Screens | A screen is one HTML file in the screens folder. The browser shows the newest file. Write one file per step. |
| .[CHIAVE-RIMOSSA].md | mcpa-certification | > |
| ./skills/motion-figure/SKILL.md | motion-figure | > |
| .[CHIAVE-RIMOSSA].md | Dither fields | A dither field is a band of moving pixels drawn with ordered dithering. It uses only three colours from the page: the paper, the accent, and the ink. Use one as |
| .[CHIAVE-RIMOSSA].md | Mechanism figures | A mechanism figure is a small interactive panel that shows how one system works. The reader drives it with one control, watches the named contents change, and r |
| .[CHIAVE-RIMOSSA].md | SMIL rules for animated lesson figures | This file holds the twelve rules in full, then one note for each rule, then a validator. The rules are facts that real figures on the course site proved. A figu |
| .[CHIAVE-RIMOSSA].md | Tokens for motion figures | These values come from the course stylesheet. The sibling skill `course-style` holds the full set. This file copies only what a motion figure needs, so this ski |
| .[CHIAVE-RIMOSSA].md | The LF toolkit and two complete examples | The course runtime puts one object on the page: `window.LF`. Figure modules use it to build DOM and SVG nodes, to make controls, and to register figures by name |
| ./skills/start-learning/SKILL.md | start-learning | > |
| ./skills/write-manual/SKILL.md | write-manual | > |
| .[CHIAVE-RIMOSSA].md | The audit | The audit reads every document, figure, listing, and quote of a manual, and prints one line per finding. It ends with `TOTAL <n>` and a count per rule. A manual |
| .[CHIAVE-RIMOSSA].md | The capture kit | Every request, response, and event that a manual shows comes from a run. The capture kit is the program that makes those runs and writes them to files. Listings |
| .[CHIAVE-RIMOSSA].md | manual.json | `manual.json` is the manifest of one manual. It holds the identity, the pin, the palette, the ranked sources, and the order of parts and sections. The build val |
| .[CHIAVE-RIMOSSA].md | Prose rules | A manual uses limits from Simplified Technical English. The audit checks each limit on every prose span: paragraphs, list items, table cells, takeaways, figure  |
| .[CHIAVE-RIMOSSA].md | Research, sources, and the conflict register | A manual makes no claim that you cannot trace to a ranked source. Do the research before you write the first section, and keep it in files beside the manual. |
| .[CHIAVE-RIMOSSA].md | Section template | Copy this skeleton into `sections/<n>-<m>-<slug>.md`. Replace every value. Keep the order of the blocks. |
