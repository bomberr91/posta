# Indice automatico della miniera — 01/11 12:07
TOTALE PEZZI INDICIZZATI: 180

| ./.claude/skills/blueprint-figure/SKILL.md | blueprint-figure | > |
| ./.claude/skills/blueprint-figure/references/checks.md | Checks a figure must pass | Each check below has a rule name and a test that a script or a reviewer can run on the SVG file. Inside the AI Engineering from Scratch repo, `scripts/audit_man |
| ./.claude/skills/blueprint-figure/references/grammar.md | Figure grammar: tokens, hues, arrows, sizes | This file holds the exact values that a figure uses. The sibling skill `course-style` holds the full course tokens. The values below are copied here so this ski |
| ./.claude/skills/blueprint-figure/references/kinds.md | The nine figure kinds | Each figure has one kind. Pick the kind from the claim, then use the layout below. All coordinates are in viewBox units at width 640. Keep content between x 20  |
| ./.claude/skills/build-project/SKILL.md | build-project | > |
| ./.claude/skills/check-understanding/SKILL.md | check-understanding | Phase quiz for AI Engineering from Scratch. Trigger with "quiz me", "test phase", "check my understanding", "do I know phase 3", or `/check-understanding <phase |
| ./.claude/skills/claude-certification/SKILL.md | claude-certification | > |
| ./.claude/skills/course-guide/SKILL.md | course-guide | > |
| ./.claude/skills/course-style/SKILL.md | course-style | > |
| ./.claude/skills/course-style/references/accessibility.md | Accessibility and reduced motion | These defaults apply to every page, card, and figure in the course. Each one is a value or a markup rule that you can check in the output. |
| ./.claude/skills/course-style/references/labels-and-layout.md | Labels and layout | Course figures for lessons, the README, and the home page use one global number. |
| ./.claude/skills/course-style/references/plain-english.md | Plain technical English | Course prose follows a short set of rules taken from Simplified Technical English. Each rule is a test that a reviewer or a script can run on the text. The manu |
| ./.claude/skills/course-style/references/tokens.md | Tokens | The course has two token sets. Pages and site components use the site tokens. Static manual figures use the `--m-` figure tokens, so a figure renders the same i |
| ./.claude/skills/course-style/references/typography.md | Typography | The course uses three families. The display face is a pixel font for headings. The serif carries reading text. The mono carries labels, meta lines, figure text, |
| ./.claude/skills/find-your-level/SKILL.md | find-your-level | > |
| ./.claude/skills/find-your-level/references/answer-key.md | Placement Quiz Answer Key | Read only the round the learner has just completed. Keep later rounds out of |
| ./.claude/skills/isometric-explainer/SKILL.md | isometric-explainer | > |
| ./.claude/skills/isometric-explainer/references/colour-and-ink.md | Colour and ink | This is the look for every machine page. Colour shows what each part is made of. Ink shows its shape. The motion and the model stay the same. Only the paint cha |
| ./.claude/skills/isometric-explainer/references/concept.md | Invent the machine | Each part of the machine does one step of the process. After one run, a reader can explain the process without the captions. |
| ./.claude/skills/isometric-explainer/references/geometry.md | Geometry | All geometry is built once in Node by the build script. The browser only moves groups, toggles their visibility and rebuilds a few paths. |
| ./.claude/skills/isometric-explainer/references/live.md | The live script | The build script inlines the kit, the model, a data object `D` and the live script into one `<script>`. The live script turns model events into motion and keeps |
| ./.claude/skills/isometric-explainer/references/state-model.md | The state model | The model is a plain ES module with no DOM, no timers and no randomness. The build script inlines it into the page, and the tests import it directly. Everything |
| ./.claude/skills/isometric-explainer/references/verify.md | Verification loop | Do not trust the code. Look at the pixels. Run this loop after each build, and fix every finding before the next run. |
| ./.claude/skills/learn/SKILL.md | learn | > |
| ./.claude/skills/learn-agent-skills/SKILL.md | learn-agent-skills | > |
| ./.claude/skills/learn-mcp/SKILL.md | learn-mcp | > |
| ./.claude/skills/learn-reverse-engineering/SKILL.md | learn-reverse-engineering | > |
| ./.claude/skills/lesson-screen/SKILL.md | lesson-screen | > |
| ./.claude/skills/lesson-screen/references/build.md | Build a figure on the fly | A built figure is one page that a tutor makes for one lesson while the lesson runs. This page holds the stages of a build, the contract that every built page fo |
| ./.claude/skills/lesson-screen/references/hosts.md | Hosts | The lesson screen needs three things: Node.js 20 or later, a local port, and a browser on the learner's machine. This page lists the cases and what to do in eac |
| ./.claude/skills/lesson-screen/references/screens.md | Screens | A screen is one HTML file in the screens folder. The browser shows the newest file. Write one file per step. |
| ./.claude/skills/mcpa-certification/SKILL.md | mcpa-certification | > |
| ./.claude/skills/motion-figure/SKILL.md | motion-figure | > |
| ./.claude/skills/motion-figure/references/dither-fields.md | Dither fields | A dither field is a band of moving pixels drawn with ordered dithering. It uses only three colours from the page: the paper, the accent, and the ink. Use one as |
| ./.claude/skills/motion-figure/references/mechanism-figures.md | Mechanism figures | A mechanism figure is a small interactive panel that shows how one system works. The reader drives it with one control, watches the named contents change, and r |
| ./.claude/skills/motion-figure/references/smil-rules.md | SMIL rules for animated lesson figures | This file holds the twelve rules in full, then one note for each rule, then a validator. The rules are facts that real figures on the course site proved. A figu |
| ./.claude/skills/motion-figure/references/tokens.md | Tokens for motion figures | These values come from the course stylesheet. The sibling skill `course-style` holds the full set. This file copies only what a motion figure needs, so this ski |
| ./.claude/skills/motion-figure/references/toolkit.md | The LF toolkit and two complete examples | The course runtime puts one object on the page: `window.LF`. Figure modules use it to build DOM and SVG nodes, to make controls, and to register figures by name |
| ./.claude/skills/start-learning/SKILL.md | start-learning | > |
| ./.claude/skills/write-manual/SKILL.md | write-manual | > |
| ./.claude/skills/write-manual/references/audit.md | The audit | The audit reads every document, figure, listing, and quote of a manual, and prints one line per finding. It ends with `TOTAL <n>` and a count per rule. A manual |
| ./.claude/skills/write-manual/references/capture-kit.md | The capture kit | Every request, response, and event that a manual shows comes from a run. The capture kit is the program that makes those runs and writes them to files. Listings |
| ./.claude/skills/write-manual/references/manual-json.md | manual.json | `manual.json` is the manifest of one manual. It holds the identity, the pin, the palette, the ranked sources, and the order of parts and sections. The build val |
| ./.claude/skills/write-manual/references/prose-rules.md | Prose rules | A manual uses limits from Simplified Technical English. The audit checks each limit on every prose span: paragraphs, list items, table cells, takeaways, figure  |
| ./.claude/skills/write-manual/references/research-and-sources.md | Research, sources, and the conflict register | A manual makes no claim that you cannot trace to a ranked source. Do the research before you write the first section, and keep it in files beside the manual. |
| ./.claude/skills/write-manual/references/section-template.md | Section template | Copy this skeleton into `sections/<n>-<m>-<slug>.md`. Replace every value. Keep the order of the blocks. |
| ./certifications/claude/lessons/03-prompting-and-task-decomposition/docs/en.md | Turn a Request Into a Testable Contract | > A strong prompt does not merely describe what to write. It makes success observable before generation begins. |
| ./certifications/claude/lessons/19-claude-code-memory-rules-skills-and-ci/docs/en.md | Claude Code Memory, Rules, Skills, and CI | > Put stable guidance where its scope is true, and executable constraints where failure is unacceptable. |
| ./certifications/claude/lessons/19-claude-code-memory-rules-skills-and-ci/outputs/configuration-scope-audit.md | Configuration Scope Audit: Python Service | The root guide contains purpose, layout, canonical commands, security boundary, |
| ./certifications/claude/lessons/19-claude-code-memory-rules-skills-and-ci/outputs/migration-review-skill/SKILL.md | migration-review | Review database migration files when a change adds or modifies paths under migrations/. Use it before merge to collect forward, rollback, locking, and data-safe |
| ./certifications/claude/lessons/19-claude-code-memory-rules-skills-and-ci/outputs/migration-review-skill/references/review-checklist.md | Migration Review Checklist | - Identify the schema and data transition. |
| ./certifications/mcpa/lessons/13-prompts-and-completion/docs/en.md | Prompt Templates and Argument Completion | > A prompt is a template the server writes and the user chooses to run. Nothing about it should surprise the person who picked it. |
| ./certifications/mcpa/lessons/13-prompts-and-completion/outputs/prompt-and-completion-reference.md | Prompt and Completion Reference | A one-page reference for the MCPA "Interactions and Execution" domain, aligned to MCP 2026-07-28. |
| ./phases/11-llm-engineering/01-prompt-engineering/docs/en.md | Prompt Engineering: Techniques & Patterns | > Most people write prompts like they are texting a friend. Then they wonder why a 200-billion parameter model gives mediocre answers. Prompt engineering is not |
| ./phases/11-llm-engineering/01-prompt-engineering/outputs/prompt-prompt-optimizer.md | prompt-prompt-optimizer | Takes a draft prompt and rewrites it using proven prompt engineering patterns for maximum effectiveness across models |
| ./phases/11-llm-engineering/01-prompt-engineering/outputs/skill-prompt-patterns.md | skill-prompt-patterns | Decision framework for choosing the right prompt pattern based on task type, reliability requirements, and target model |
| ./phases/11-llm-engineering/15-prompt-caching/docs/en.md | Prompt Caching and Context Caching | > Your system prompt is 4,000 tokens. Your RAG context is 20,000 tokens. You send both with every request. You also pay for both — every time. Prompt caching le |
| ./phases/11-llm-engineering/15-prompt-caching/outputs/skill-prompt-caching-planner.md | prompt-caching-planner | Design a cache-friendly prompt layout and pick the right provider caching mode. |
| ./phases/13-tools-and-protocols/10-mcp-resources-and-prompts/docs/en.md | MCP Resources and Prompts: Addressable Context for Stateless | > Tools perform operations. Resources expose addressable content. Prompts package user-selected message templates. A good MCP server keeps those contracts separ |
| ./phases/13-tools-and-protocols/10-mcp-resources-and-prompts/outputs/skill-primitive-splitter.md | primitive-splitter | Review an MCP server design and separate tools, resources, prompts, caching, and subscriptions using the 2026-07-28 contract. |
| ./phases/13-tools-and-protocols/22-skills-and-agent-sdks/docs/en.md | Agent Skills: Portable Contract and Runtime Boundary | > A skill is not a long prompt with a better filename. It is a discoverable package of instructions, resources, and executable helpers that enters an agent's co |
| ./phases/13-tools-and-protocols/22-skills-and-agent-sdks/outputs/skill-contract-reviewer/SKILL.md | skill-contract-reviewer | Validate an Agent Skill package and choose the right instruction, capability, or lifecycle primitive before implementation. |
| ./phases/13-tools-and-protocols/22-skills-and-agent-sdks/outputs/skill-contract-reviewer/references/contract.md | Portable contract checklist | - The bundle is a directory containing a regular `SKILL.md` file. |
| ./phases/13-tools-and-protocols/22-skills-and-agent-sdks/outputs/skill-contract-reviewer/references/decision-model.md | Primitive decision model | Select by responsibility. More than one primitive may be correct. |
| ./phases/13-tools-and-protocols/24-skill-discovery-and-progressive-disclosure/docs/en.md | Skill Discovery and Progressive Disclosure | > A skill becomes useful before its body is loaded. Its name and description earn a place in the catalog; its deeper files earn context only when the task reach |
| ./phases/13-tools-and-protocols/24-skill-discovery-and-progressive-disclosure/outputs/skill-catalog-builder/SKILL.md | skill-catalog-builder | Build a bounded Agent Skill catalog across explicit discovery scopes and report collisions before loading instruction bodies. |
| ./phases/13-tools-and-protocols/24-skill-discovery-and-progressive-disclosure/outputs/skill-catalog-builder/references/discovery-contract.md | Discovery contract | Discovery has three disclosure levels: |
| ./phases/13-tools-and-protocols/25-skill-invocation-and-routing/docs/en.md | Skill Invocation and Routing | > Invocation is an authority decision followed by a relevance decision. A good description helps the model choose; a good policy decides whether that choice is  |
| ./phases/13-tools-and-protocols/25-skill-invocation-and-routing/outputs/skill-invocation-router/SKILL.md | skill-invocation-router | Design and test explicit human, implicit model or agent, programmatic application, bounded skill-composition, and harness activation policies for an Agent Skill |
| ./phases/13-tools-and-protocols/25-skill-invocation-and-routing/outputs/skill-invocation-router/references/invocation-model.md | Invocation model | | Channel | Initiator | Selection | Typical use | |
| ./phases/13-tools-and-protocols/26-skill-permissions-sandboxes-and-trust/docs/en.md | Skill Permissions, Sandboxes, and Trust | > A skill can suggest an action. Only the host can authorize it, only an isolation boundary can contain it, and only verification can tell you whether it worked |
| ./phases/13-tools-and-protocols/26-skill-permissions-sandboxes-and-trust/outputs/skill-safety-reviewer/SKILL.md | skill-safety-reviewer | Review a skill-requested filesystem, command, network, secret, or destructive action against an explicit sandbox policy without executing it. |
| ./phases/13-tools-and-protocols/26-skill-permissions-sandboxes-and-trust/outputs/skill-safety-reviewer/references/threat-model.md | Threat model | Review these boundaries independently: |
| ./phases/13-tools-and-protocols/27-skill-evals-packaging-and-portability/docs/en.md | Skill Evals, Packaging, and Portability | > A skill is finished when its package survives linting, routes on the right requests, improves a measured task, stays inside policy, and degrades honestly on a |
| ./phases/13-tools-and-protocols/27-skill-evals-packaging-and-portability/outputs/skill-release-gate/SKILL.md | skill-release-gate | Evaluate an Agent Skill bundle for structural integrity, trigger quality, artifact improvement, script correctness, safety, installed-tree integrity, and target |
| ./phases/13-tools-and-protocols/27-skill-evals-packaging-and-portability/outputs/skill-release-gate/references/eval-contract.md | Evaluation contract | A release candidate passes only when all required surfaces pass: |
| ./phases/14-agent-engineering/10-skill-libraries-voyager/docs/en.md | Skill Libraries and Lifelong Learning (Voyager) | > Voyager (Wang et al., TMLR 2024) treats executable code as a skill. Skills are named, retrievable, composable, and refined by environment feedback. This is th |
| ./phases/14-agent-engineering/10-skill-libraries-voyager/outputs/skill-skill-library.md | skill-library | Generate a Voyager-shaped skill library with registration, retrieval by similarity, compositional execution, and failure-driven refinement. |
| ./phases/14-agent-engineering/27-prompt-injection-defense/docs/en.md | Prompt Injection and the PVE Defense | > Greshake et al. (AISec 2023) established indirect prompt injection as the defining agent security problem. Attacker plants instructions in data the agent retr |
| ./phases/14-agent-engineering/27-prompt-injection-defense/outputs/skill-injection-defense.md | injection-defense | Build a PVE (Prompt-Validator-Executor) layer with source-tagged content, injection-marker scanning, and allowlist navigation for any agent runtime. |
| ./phases/17-infrastructure-and-production/14-prompt-semantic-caching/docs/en.md | Prompt Caching and Semantic Caching Economics | > **Pricing snapshot dated 2026-04.** Numeric claims below reflect vendor rate cards captured at this lesson's publication; verify against the linked docs befor |
| ./phases/17-infrastructure-and-production/14-prompt-semantic-caching/outputs/skill-cache-auditor.md | cache-auditor | Audit an LLM prompt template and traffic pattern for cacheability. Recommend prompt restructure, TTL choice, parallelization fix, and semantic-cache threshold. |
| ./phases/18-ethics-safety-alignment/15-indirect-prompt-injection/docs/en.md | Indirect Prompt Injection — Production Attack Surface | > Indirect prompt injection (IPI) embeds instructions inside external content — a web page, an email, a shared document, a support ticket — consumed by an agent |
| ./phases/18-ethics-safety-alignment/15-indirect-prompt-injection/outputs/skill-ipi-audit.md | ipi-audit | Audit an agentic deployment for indirect prompt injection exposure and information-flow-control coverage. |
| ./phases/19-capstone-projects/83-prompt-injection-detector/docs/en.md | Capstone 83 — Prompt Injection Detector | > A detector is a function from prompt to confidence and category. Anything else is a vibe. |
| ./phases/19-capstone-projects/83-prompt-injection-detector/outputs/skill-prompt-injection-detector.md | skill-prompt-injection-detector | Layered detector pipeline that returns a category and confidence for any prompt, with measurable precision and recall |
| ./projects/prompt-regression-tester/README.md | Prompt Regression Tester | A prompt-change review kit that identifies exactly which user commitments broke. |
| ./projects/prompt-regression-tester/stages/01-validate-cases/docs/en.md | Validate cases before scoring | **Stage 1 of 4.** Python. Plan about 2 hours. |
| ./projects/prompt-regression-tester/stages/02-score-recordings/docs/en.md | Score recorded outputs without a model | **Stage 2 of 4.** Python. Plan about 2 hours. |
| ./projects/prompt-regression-tester/stages/02-score-recordings/starter/STAGE.md | starter | Continue editing main.py in the workspace created at stage 1. |
| ./projects/prompt-regression-tester/stages/03-pair-revisions/docs/en.md | Compare the same cases across revisions | **Stage 3 of 4.** Python. Plan about 2 hours. |
| ./projects/prompt-regression-tester/stages/03-pair-revisions/starter/STAGE.md | starter | Continue editing main.py in the workspace created at stage 1. |
| ./projects/prompt-regression-tester/stages/04-gate-releases/docs/en.md | Gate releases on explicit tolerances | **Stage 4 of 4.** Python. Plan about 2 hours. |
| ./projects/prompt-regression-tester/stages/04-gate-releases/starter/STAGE.md | starter | Continue editing main.py in the workspace created at stage 1. |
| ./projects/self-improving-skill-loop/README.md | Self-Improving Skill Loop | A correction-to-skill experiment runner preserving sources, preventing leakage and supporting rollback. |
| ./projects/self-improving-skill-loop/stages/01-dataset/docs/en.md | Split labeled cases without identity leakage | **Stage 1 of 4.** Python. Plan about 2 hours. |
| ./projects/self-improving-skill-loop/stages/02-skill/docs/en.md | Execute and score a transparent routing skill | **Stage 2 of 4.** Python. Plan about 2 hours. |
| ./projects/self-improving-skill-loop/stages/03-propose/docs/en.md | Propose rules from development errors only | **Stage 3 of 4.** Python. Plan about 2 hours. |
| ./projects/self-improving-skill-loop/stages/04-promotion/docs/en.md | Require a separate gate before promotion | **Stage 4 of 4.** Python. Plan about 2 hours. |
| ./projects/skill-installer/README.md | Cross-Agent Skill Installer | A cross-agent upgrade tool promising a reviewable diff and no lost local edits. |
| ./projects/skill-installer/stages/01-bundle/docs/en.md | Validate a portable bundle | **Stage 1 of 4.** Typescript. Plan about 2 hours. |
| ./projects/skill-installer/stages/01-bundle/starter/stage-1.md | starter | Implement stage 1: Validate a portable bundle. Keep earlier behavior passing. |
| ./projects/skill-installer/stages/02-translate/docs/en.md | Translate metadata and hash content | **Stage 2 of 4.** Typescript. Plan about 2 hours. |
| ./projects/skill-installer/stages/02-translate/starter/stage-2.md | starter | Implement stage 2: Translate metadata and hash content. Keep earlier behavior passing. |
| ./projects/skill-installer/stages/03-install/docs/en.md | Install atomically within a root | **Stage 3 of 4.** Typescript. Plan about 2 hours. |
| ./projects/skill-installer/stages/03-install/starter/stage-3.md | starter | Implement stage 3: Install atomically within a root. Keep earlier behavior passing. |
| ./projects/skill-installer/stages/04-upgrades/docs/en.md | Protect edits during upgrades | **Stage 4 of 4.** Typescript. Plan about 2 hours. |
| ./projects/skill-installer/stages/04-upgrades/starter/stage-4.md | starter | Implement stage 4: Protect edits during upgrades. Keep earlier behavior passing. |
| ./projects/skill-router/README.md | Skill Router | A routing debugger showing why the wrong skill activated and how to fix a rule. |
| ./projects/skill-router/examples/skills/check-tests/SKILL.md | "check-tests" | "Run the local test evidence check" |
| ./projects/skill-router/examples/skills/release-publish/SKILL.md | "release-publish" | "Publish an approved Orchard release" |
| ./projects/skill-router/examples/skills/release-review/SKILL.md | "release-review" | "Review Orchard deployment manifests" |
| ./projects/skill-router/stages/01-catalog/docs/en.md | Parse a typed skill catalog | **Stage 1 of 4.** Typescript. Plan about 2 hours. |
| ./projects/skill-router/stages/01-catalog/starter/stage-1.md | starter | Implement stage 1: Parse a typed skill catalog. Keep earlier behavior passing. |
| ./projects/skill-router/stages/02-score/docs/en.md | Score words and repository paths | **Stage 2 of 4.** Typescript. Plan about 2 hours. |
| ./projects/skill-router/stages/02-score/starter/stage-2.md | starter | Implement stage 2: Score words and repository paths. Keep earlier behavior passing. |
| ./projects/skill-router/stages/03-dependencies/docs/en.md | Resolve dependencies before execution | **Stage 3 of 4.** Typescript. Plan about 2 hours. |
| ./projects/skill-router/stages/03-dependencies/starter/stage-3.md | starter | Implement stage 3: Resolve dependencies before execution. Keep earlier behavior passing. |
| ./projects/skill-router/stages/04-route/docs/en.md | Abstain on ambiguous or blocked requests | **Stage 4 of 4.** Typescript. Plan about 2 hours. |
| ./projects/skill-router/stages/04-route/starter/stage-4.md | starter | Implement stage 4: Abstain on ambiguous or blocked requests. Keep earlier behavior passing. |
| ./projects/skill-scanner/README.md | Skill Supply-Chain Scanner | A skill-change review assistant quoting newly introduced capabilities. |
| ./projects/skill-scanner/examples/benign/SKILL.md | orchard-review | Review a release proposal |
| ./projects/skill-scanner/examples/reviewable/SKILL.md | orchard-review | Review a release proposal |
| ./projects/skill-scanner/stages/01-retain-byte-accurate-source-spans/docs/en.md | Retain byte-accurate source spans | **Stage 1 of 4.** Rust. Plan about 2 hours. |
| ./projects/skill-scanner/stages/02-detect-named-advisory-patterns/docs/en.md | Detect named advisory patterns | **Stage 2 of 4.** Rust. Plan about 2 hours. |
| ./projects/skill-scanner/stages/03-score-distinct-evidence-without-inflation/docs/en.md | Score distinct evidence without inflation | **Stage 3 of 4.** Rust. Plan about 2 hours. |
| ./projects/skill-scanner/stages/04-build-an-explicit-review-gate/docs/en.md | Build an explicit review gate | **Stage 4 of 4.** Rust. Plan about 2 hours. |
| ./projects/skill-validator/README.md | SKILL.md Validator and Loader | A compatibility linter explaining why a skill works in one agent but fails in another. |
| ./projects/skill-validator/examples/orchard-release/SKILL.md | "orchard-release" | "Check deployment evidence and recovery conditions." |
| ./projects/skill-validator/examples/orchard-release/references/restore.md | references | The Orchard restore rehearsal finished at 09:20 UTC with two verified records. |
| ./projects/skill-validator/stages/01-parse-an-explicit-frontmatter-subset/docs/en.md | Parse an explicit frontmatter subset | "Check \"replicas\" first" |
| ./projects/skill-validator/stages/02-validate-names-and-descriptions/docs/en.md | Validate names and descriptions | **Stage 2 of 4.** Rust. Plan about 2 hours. |
| ./projects/skill-validator/stages/03-contain-resource-paths/docs/en.md | Contain resource paths | **Stage 3 of 4.** Rust. Plan about 2 hours. |
| ./projects/skill-validator/stages/04-load-context-within-a-character-budget/docs/en.md | Load context within a character budget | **Stage 4 of 4.** Rust. Plan about 2 hours. |
| ./skills/blueprint-figure/SKILL.md | blueprint-figure | > |
| ./skills/blueprint-figure/references/checks.md | Checks a figure must pass | Each check below has a rule name and a test that a script or a reviewer can run on the SVG file. Inside the AI Engineering from Scratch repo, `scripts/audit_man |
| ./skills/blueprint-figure/references/grammar.md | Figure grammar: tokens, hues, arrows, sizes | This file holds the exact values that a figure uses. The sibling skill `course-style` holds the full course tokens. The values below are copied here so this ski |
| ./skills/blueprint-figure/references/kinds.md | The nine figure kinds | Each figure has one kind. Pick the kind from the claim, then use the layout below. All coordinates are in viewBox units at width 640. Keep content between x 20  |
| ./skills/build-project/SKILL.md | build-project | > |
| ./skills/check-understanding/SKILL.md | check-understanding | Phase quiz for AI Engineering from Scratch. Trigger with "quiz me", "test phase", "check my understanding", "do I know phase 3", or `/check-understanding <phase |
| ./skills/claude-certification/SKILL.md | claude-certification | > |
| ./skills/course-guide/SKILL.md | course-guide | > |
| ./skills/course-style/SKILL.md | course-style | > |
| ./skills/course-style/references/accessibility.md | Accessibility and reduced motion | These defaults apply to every page, card, and figure in the course. Each one is a value or a markup rule that you can check in the output. |
| ./skills/course-style/references/labels-and-layout.md | Labels and layout | Course figures for lessons, the README, and the home page use one global number. |
| ./skills/course-style/references/plain-english.md | Plain technical English | Course prose follows a short set of rules taken from Simplified Technical English. Each rule is a test that a reviewer or a script can run on the text. The manu |
| ./skills/course-style/references/tokens.md | Tokens | The course has two token sets. Pages and site components use the site tokens. Static manual figures use the `--m-` figure tokens, so a figure renders the same i |
| ./skills/course-style/references/typography.md | Typography | The course uses three families. The display face is a pixel font for headings. The serif carries reading text. The mono carries labels, meta lines, figure text, |
| ./skills/find-your-level/SKILL.md | find-your-level | > |
| ./skills/find-your-level/references/answer-key.md | Placement Quiz Answer Key | Read only the round the learner has just completed. Keep later rounds out of |
| ./skills/isometric-explainer/SKILL.md | isometric-explainer | > |
| ./skills/isometric-explainer/references/colour-and-ink.md | Colour and ink | This is the look for every machine page. Colour shows what each part is made of. Ink shows its shape. The motion and the model stay the same. Only the paint cha |
| ./skills/isometric-explainer/references/concept.md | Invent the machine | Each part of the machine does one step of the process. After one run, a reader can explain the process without the captions. |
| ./skills/isometric-explainer/references/geometry.md | Geometry | All geometry is built once in Node by the build script. The browser only moves groups, toggles their visibility and rebuilds a few paths. |
| ./skills/isometric-explainer/references/live.md | The live script | The build script inlines the kit, the model, a data object `D` and the live script into one `<script>`. The live script turns model events into motion and keeps |
| ./skills/isometric-explainer/references/state-model.md | The state model | The model is a plain ES module with no DOM, no timers and no randomness. The build script inlines it into the page, and the tests import it directly. Everything |
| ./skills/isometric-explainer/references/verify.md | Verification loop | Do not trust the code. Look at the pixels. Run this loop after each build, and fix every finding before the next run. |
| ./skills/learn/SKILL.md | learn | > |
| ./skills/learn-agent-skills/SKILL.md | learn-agent-skills | > |
| ./skills/learn-mcp/SKILL.md | learn-mcp | > |
| ./skills/learn-reverse-engineering/SKILL.md | learn-reverse-engineering | > |
| ./skills/lesson-screen/SKILL.md | lesson-screen | > |
| ./skills/lesson-screen/references/build.md | Build a figure on the fly | A built figure is one page that a tutor makes for one lesson while the lesson runs. This page holds the stages of a build, the contract that every built page fo |
| ./skills/lesson-screen/references/hosts.md | Hosts | The lesson screen needs three things: Node.js 20 or later, a local port, and a browser on the learner's machine. This page lists the cases and what to do in eac |
| ./skills/lesson-screen/references/screens.md | Screens | A screen is one HTML file in the screens folder. The browser shows the newest file. Write one file per step. |
| ./skills/mcpa-certification/SKILL.md | mcpa-certification | > |
| ./skills/motion-figure/SKILL.md | motion-figure | > |
| ./skills/motion-figure/references/dither-fields.md | Dither fields | A dither field is a band of moving pixels drawn with ordered dithering. It uses only three colours from the page: the paper, the accent, and the ink. Use one as |
| ./skills/motion-figure/references/mechanism-figures.md | Mechanism figures | A mechanism figure is a small interactive panel that shows how one system works. The reader drives it with one control, watches the named contents change, and r |
| ./skills/motion-figure/references/smil-rules.md | SMIL rules for animated lesson figures | This file holds the twelve rules in full, then one note for each rule, then a validator. The rules are facts that real figures on the course site proved. A figu |
| ./skills/motion-figure/references/tokens.md | Tokens for motion figures | These values come from the course stylesheet. The sibling skill `course-style` holds the full set. This file copies only what a motion figure needs, so this ski |
| ./skills/motion-figure/references/toolkit.md | The LF toolkit and two complete examples | The course runtime puts one object on the page: `window.LF`. Figure modules use it to build DOM and SVG nodes, to make controls, and to register figures by name |
| ./skills/start-learning/SKILL.md | start-learning | > |
| ./skills/write-manual/SKILL.md | write-manual | > |
| ./skills/write-manual/references/audit.md | The audit | The audit reads every document, figure, listing, and quote of a manual, and prints one line per finding. It ends with `TOTAL <n>` and a count per rule. A manual |
| ./skills/write-manual/references/capture-kit.md | The capture kit | Every request, response, and event that a manual shows comes from a run. The capture kit is the program that makes those runs and writes them to files. Listings |
| ./skills/write-manual/references/manual-json.md | manual.json | `manual.json` is the manifest of one manual. It holds the identity, the pin, the palette, the ranked sources, and the order of parts and sections. The build val |
| ./skills/write-manual/references/prose-rules.md | Prose rules | A manual uses limits from Simplified Technical English. The audit checks each limit on every prose span: paragraphs, list items, table cells, takeaways, figure  |
| ./skills/write-manual/references/research-and-sources.md | Research, sources, and the conflict register | A manual makes no claim that you cannot trace to a ranked source. Do the research before you write the first section, and keep it in files beside the manual. |
| ./skills/write-manual/references/section-template.md | Section template | Copy this skeleton into `sections/<n>-<m>-<slug>.md`. Replace every value. Keep the order of the blocks. |
