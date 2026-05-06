# Claude Code

Claude Code is an agentic coding tool that operates through several core architectural and functional elements designed to bridge the gap between a language model and a terminal environment. [1, 2] 
The primary elements of Claude Code include:
## 1. The Agentic Loop
Claude Code works through a continuous cycle composed of three main phases: [1] 

* Context Gathering: Searching files and terminal output to understand the codebase.
* Action: Taking steps like editing files, running shell commands, or creating new modules.
* Verification: Running tests or using linter output to ensure changes are correct. [1, 3, 4] 

## 2. Core Components
The system is built on two foundational layers: [1] 

* Models: The "brains" (e.g., Claude 3.5 Sonnet) that reason and plan.
* Tools: The capabilities that allow Claude to interact with your machine, such as file operations, git integration, and shell execution. [1, 5, 6] 

## 3. Context Management
To handle large repositories efficiently, Claude Code uses:

* CLAUDE.md: A file for project-specific instructions, conventions, and architectural decisions that Claude reads every session.
* Auto Memory: Automatically saved learnings (in MEMORY.md) about project patterns and user preferences.
* /compact: A command to summarize the conversation history and free up space in the context window. [1, 2, 4, 5, 7] 

## 4. Command Interface
Users interact with Claude Code using several types of inputs: [7, 8] 

* Slash Commands: Built-in operations for session management (e.g., /clear, /help, /cost).
* Skills: Prompt-based workflows (e.g., /review, /simplify, /debug) that use markdown files to give Claude complex instructions.
* Keyboard Shortcuts: Rapid actions like Shift+Tab to cycle permission modes or Esc+Esc to open the rewind/undo menu. [5, 6, 7, 9, 10] 

## 5. Extension Features
Advanced workflows are enabled through:

* MCP (Model Context Protocol): Connects Claude to external services like databases, Slack, or browsers.
* Subagents: Isolated execution environments that Claude can spawn to perform parallel research or complex investigation without cluttering the main session.
* Hooks: Automated scripts or prompts triggered by specific events, such as running a linter after every file edit. [2, 4, 11, 12, 13] 

## 6. Permission and Safety Modes [14, 15] 
Claude Code includes varying levels of autonomy: [1, 4] 

* Normal Mode: Claude asks for permission before every file edit or command.
* Auto-Accept Mode: Automatically approves edits and common filesystem commands.
* Plan Mode: Restricts Claude to read-only tools so it can only propose changes for you to review. [1, 7, 10] 

[1] [https://code.claude.com](https://code.claude.com/docs/en/how-claude-code-works)
[2] [https://code.claude.com](https://code.claude.com/docs/en/features-overview)
[3] [https://www.anthropic.com](https://www.anthropic.com/product/claude-code#:~:text=Developing%20across%20the%20whole%20codebase%20Claude%20Code,at%20a%20scale%2C%20saving%20days%20of%20work.)
[4] [https://code.claude.com](https://code.claude.com/docs/en/best-practices)
[5] [https://timdietrich.me](https://timdietrich.me/blog/claude-code-commands-guide/)
[6] [https://devhints.io](https://devhints.io/claude-code)
[7] [https://batsov.com](https://batsov.com/articles/2026/03/11/essential-claude-code-skills-and-commands/)
[8] [https://www.adventureppc.com](https://www.adventureppc.com/blog/the-complete-claude-code-cheat-sheet-25-commands-and-prompts-every-beginner-should-know)
[9] [https://code.claude.com](https://code.claude.com/docs/en/skills)
[10] [https://dev.to](https://dev.to/akari_iku/ive-organised-the-claude-code-commands-including-some-hidden-ones-op0)
[11] [https://code.claude.com](https://code.claude.com/docs/en/hooks-guide)
[12] [https://pub.towardsai.net](https://pub.towardsai.net/claude-code-extensions-explained-skills-mcp-hooks-subagents-agent-teams-plugins-9294907e84ff)
[13] [https://www.mindstudio.ai](https://www.mindstudio.ai/blog/claude-code-business-owners-5-core-concepts#:~:text=Can%20Claude%20Code%20connect%20to%20business%20tools,Anthropic%20and%20from%20the%20broader%20developer%20community.)
[14] [https://blog.promptlayer.com](https://blog.promptlayer.com/claude-code-behind-the-scenes-of-the-master-agent-loop/#:~:text=Safety%2C%20memory%2C%20and%20transparency%20Claude%20Code%20implements,usage%20%28MCP/web%29%20all%20require%20explicit%20allow/deny%20decisions.)
[15] [https://blog.vidocsecurity.com](https://blog.vidocsecurity.com/blog/claude-code-security-what-it-actually-secures#:~:text=Anthropic%20has%20put%20real%20engineering%20into%20controlling,it%20shows%20up%20directly%20in%20the%20code.)

Beyond basic file editing, LSP (Language Server Protocol) and Skills are the specialized features that turn Claude Code from a generalist assistant into a deeply integrated developer tool. [1, 2] 
## 1. Language Server Protocol (LSP)
LSP provides Claude with "IDE-level" intelligence, moving its understanding from simple text searching to semantic code awareness. [2, 3] 

* Capabilities: It enables nine specific operations, including goToDefinition, findReferences, hover (for type signatures/docs), and call hierarchy. [2, 4] 
* Performance: Semantic lookups are up to 900x faster than traditional text searches (grep), reducing multi-second searches to milliseconds. [2, 5] 
* Real-time Diagnostics: Claude receives automatic feedback on type errors or missing imports immediately after an edit, often fixing bugs in the same turn. [4, 6] 
* Setup: It requires the language server binary (e.g., pyright, rust-analyzer) installed on your system PATH and the corresponding plugin enabled in Claude Code. [2, 7] 

## 2. Skills
Skills are reusable, prompt-based workflows that teach Claude how to handle repeatable tasks or follow specific team processes. [8, 9] 

* Structure: Each skill is a directory containing a SKILL.md file. This file uses YAML frontmatter to define when it should be triggered and Markdown for the actual instructions. [10, 11] 
* Dynamic Injection: Skills can execute shell commands (e.g., git diff or gh pr view) and inject the live output directly into the prompt before Claude reads it. [10] 
* Progressive Disclosure: Unlike CLAUDE.md, which is always loaded, a skill’s body only enters the context window when invoked. This prevents "context rot" and saves tokens. [1, 8, 9, 10] 
* Bundled vs. Custom:
* Bundled: Pre-installed skills like /debug, /simplify, and /summarize-changes.
   * Custom: Personal workflows (stored in ~/.claude/skills/) or project-specific ones (stored in .claude/skills/). [10, 12, 13] 

## 3. Plugins & Extensions
While skills handle "how" to do things, Plugins extend "what" Claude can do by packaging multiple components together. [9, 13] 

* Composition: A single plugin can include skills, specialized agents, hooks (automation scripts), and even its own LSP configurations.
* Distribution: Plugins are designed for sharing across teams or through marketplaces like the [MCP Market](https://mcpmarket.com/tools/skills/lsp-management). [4, 11, 13, 14] 

[1] [https://corpwaters.substack.com](https://corpwaters.substack.com/p/the-ultimate-guide-to-claude-code)
[2] [https://yingtu.ai](https://yingtu.ai/en/blog/claude-code-lsp)
[3] [https://medium.com](https://medium.com/algomart/how-claude-codes-new-lsp-support-changes-the-way-you-debug-navigate-and-understand-code-d9649eb6dd33)
[4] [https://antoniocortes.com](https://antoniocortes.com/en/2026/03/10/claude-code-with-lsp-from-searching-text-to-understanding-code/)
[5] [https://www.youtube.com](https://www.youtube.com/watch?v=cPTEal0ILDI)
[6] [https://christophertkenny.com](https://christophertkenny.com/posts/2026-03-08-r-lsp-claude/)
[7] [https://code.claude.com](https://code.claude.com/docs/en/plugins-reference)
[8] [https://resources.anthropic.com](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
[9] [https://www.mindstudio.ai](https://www.mindstudio.ai/blog/what-are-claude-code-skills)
[10] [https://code.claude.com](https://code.claude.com/docs/en/skills)
[11] [https://code.claude.com](https://code.claude.com/docs/en/plugins-reference)
[12] [https://code.claude.com](https://code.claude.com/docs/en/skills)
[13] [https://code.claude.com](https://code.claude.com/docs/en/plugins)
[14] [https://mcpmarket.com](https://mcpmarket.com/tools/skills/lsp-management)
