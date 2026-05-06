# Vernacular Reference Library

The vocabulary of this course. Bookmark these. The LLM grader and the instructor will hold you accountable for using these terms correctly in your reflections, sprint presentations, and CC artifact descriptions.

## The Agile Manifesto v2.0 (Hunter, 2024)

[The Agile Manifesto v2.0 — Michael Hunter](https://www.linkedin.com/pulse/agile-manifesto-v20-michael-hunter/) — the philosophical baseline for how teams should operate in an LLM-mediated industry.

## Gang-of-Four Design Patterns

[refactoring.guru/design-patterns/catalog](https://refactoring.guru/design-patterns/catalog) — the catalog. 23 patterns in three families:

- **Creational:** Factory Method · Abstract Factory · Builder · Prototype · Singleton
- **Structural:** Adapter · Bridge · Composite · Decorator · Facade · Flyweight · Proxy
- **Behavioral:** Chain of Responsibility · Command · Iterator · Mediator · Memento · Observer · State · Strategy · Template Method · Visitor

## Enterprise Integration Patterns (Hohpe & Woolf, 2003)

[enterpriseintegrationpatterns.com/patterns/messaging/](https://www.enterpriseintegrationpatterns.com/patterns/messaging/) — 65 patterns for messaging-based systems. Key categories:

- **Channel patterns**: Point-to-Point Channel, Publish-Subscribe Channel, Datatype Channel, Invalid Message Channel, Dead Letter Channel, Guaranteed Delivery, Channel Adapter, Messaging Bridge, Message Bus.
- **Message construction**: Command Message, Document Message, Event Message, Request-Reply, Return Address, Correlation Identifier, Message Sequence, Message Expiration, Format Indicator.
- **Routing**: Pipes-and-Filters, Message Router, Content-Based Router, Message Filter, Dynamic Router, Recipient List, Splitter, Aggregator, Resequencer, Composed Message Processor, Scatter-Gather, Routing Slip, Process Manager, Message Broker.
- **Transformation**: Message Translator, Envelope Wrapper, Content Enricher, Content Filter, Claim Check, Normalizer, Canonical Data Model.
- **Endpoint**: Message Endpoint, Messaging Gateway, Messaging Mapper, Transactional Client, Polling Consumer, Event-Driven Consumer, Competing Consumers, Message Dispatcher, Selective Consumer, Durable Subscriber, Idempotent Receiver, Service Activator.

## The Perfect Framework (Hunter, 2024)

See `The-Perfect-Framework.md` in the course materials. Key concerns:

- **Scale** · **Database** (audit trails, point-in-time, document stores, streaming) · **Enterprise Messaging** · **Security** (SSO, RBAC, data permissions, menu/form/field control) · **Application** (multi-platform, model-driven architecture, offline, i18n, accessibility, analytics, units of measure) · **Workflow** (state charts, commitments) · **CI/CD** (multi-environment, versioned artifacts, one-button build) · **Documentation** (code + user) · **User Feedback Everywhere**.

## Claude Code Capabilities

See `claude-code-capabilities.md`. Key vocabulary:

- **Agentic loop** (context gathering · action · verification)
- **Models** (Opus / Sonnet / Haiku) and **Tools**
- **Context management**: CLAUDE.md, MEMORY.md, /compact
- **Command interface**: Slash commands · **Skills** · keyboard shortcuts
- **Extension features**: **MCP** (Model Context Protocol) · **Subagents** · **Hooks** · **Plugins** · **LSP**
- **Permission modes**: Normal · Auto-Accept · Plan

When you write a CC artifact's README, you must use these terms with precision. A skill is not a hook is not a subagent is not an MCP server.
