Claude Code customizations range from project-specific behavioral instructions to deep system integrations [cite: 0.5.7]. They are primarily categorized into Project Context & Guidelines [cite: 0.5.7], Custom Workflows & Automation [cite: 0.5.7], External Integrations [cite: 0.5.7], and Interface/Terminal Configuration [cite: 0.5.5]. [1, 2, 3]  
1. Project Context & Guidelines (CLAUDE.md) 
These set the master standards for how Claude understands your codebase and framework conventions [cite: 0.5.7]. 

• CLAUDE.md: A project-level markdown file placed in your root directory. It is always loaded [cite: 0.5.7] to enforce code style rules [cite: 0.5.37], testing instructions [cite: 0.5.37], and repository etiquette [cite: 0.5.37]. 
• Output Styles: Built-in behavioral settings including Explanatory (step-by-step) [cite: 0.5.6], Concise [cite: 0.5.6], Proactive [cite: 0.5.17], and Learning [cite: 0.5.17]. 
• System Prompts: Configurable via CLI flags (e.g., ) to temporarily replace or supplement Claude's default persona [cite: 0.5.11]. 

2. Workflows, Routines, & Automation 
These define specific, repeatable tasks or behaviors that Claude can run [cite: 0.5.7]. 

• Skills: File-system based workflows defined in  files within  [cite: 0.5.12]. They package complex multi-step routines [cite: 0.5.2] that Claude can invoke dynamically. 
• Subagents: Autonomous, nested agents that run in isolated context windows to handle heavy analytical or background tasks (e.g., Explore, Plan, general-purpose) [cite: 0.5.25]. 
• Hooks: Shell scripts or HTTP events that trigger on lifecycle events—like when you send a message, before Claude runs commands, or after file edits [cite: 0.5.10]. [1, 13, 14, 15, 16]  

3. External Integrations 
These connect Claude Code to external tools and services [cite: 0.5.22]. 

• Model Context Protocol (MCP): Connect Claude directly to external services like GitHub, databases, Slack, or language servers to enable symbol-level navigation and live error fetching [cite: 0.5.22]. 
• Plugins: Installable marketplace packages [cite: 0.5.5] that bundle skills, subagents, hooks, and MCP servers [cite: 0.5.22]. [4, 17, 18, 19]  

4. Interface & Terminal Customization 
These customize how you experience and operate the terminal interface [cite: 0.5.5]. 

• Terminal Themes: Configure colors, fonts, and base presets (e.g., light, dark, dark-daltonized) using  configurations [cite: 0.5.15]. 
• Status Lines & Keybindings: Customize the persistent status display at the bottom of the terminal and map keyboard shortcuts for common actions [cite: 0.5.5]. 
• Model Selection: Swap the underlying LLM (e.g., between Claude Fable, Opus, or Sonnet) globally or for a specific session [cite: 0.5.9]. [24]  

[1] https://code.claude.com/docs/en/features-overview
[2] https://www.mindstudio.ai/blog/what-is-claude-cowork-projects
[3] https://dev.to/alanwest/opencode-vs-claude-code-vs-aider-picking-the-right-ai-coding-agent-44i0
[4] https://code.claude.com/docs/en/overview
[5] https://www.mindstudio.ai/blog/claude-code-skills-large-codebases-7-layer-strategy
[6] https://github.com/anthropics/claude-code/issues/6398
[7] https://code.claude.com/docs/en/output-styles
[8] https://www.reddit.com/r/ClaudeAI/comments/1mqfxju/claude_code_adding_light_features_to_my_expo_app/
[9] https://marioottmann.com/articles/claude-code-customization-guide
[10] https://code.claude.com/docs/en/sub-agents
[11] https://levelup.gitconnected.com/a-mental-model-for-claude-code-skills-subagents-and-plugins-3dea9924bf05
[12] https://pub.towardsai.net/a-complete-beginners-guide-to-claude-code-skills-agents-hooks-plugins-mcp-085b26b73fdd
[13] https://code.claude.com/docs/en/hooks-guide
[14] https://guptadeepak.com/claude-code-for-engineers-a-practitioners-playbook-for-software-qa-and-security-teams/
[15] https://blog.gitbutler.com/parallel-claude-code
[16] https://suiteinsider.com/complete-guide-creating-claude-code-hooks/
[17] https://nimbalyst.com/blog/claude-code-plugins-guide/
[18] https://egghead.io/claude-code-is-a-platform-not-an-app~vlf9f
[19] https://medium.com/@the.gigi/claude-code-deep-dive-know-your-rivals-cb2041addd1d
[20] https://code.claude.com/docs/en/terminal-config
[21] https://www.claudepluginhub.com/themes
[22] https://mcpmarket.com/tools/skills/tabby-terminal-visual-customization
[23] https://code.claude.com/docs/en/statusline
[24] https://support.claude.com/en/articles/11940350-claude-code-model-configuration

