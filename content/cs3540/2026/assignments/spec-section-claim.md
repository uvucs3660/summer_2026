# Claim Your Spec Section

**Due:** Sun Sep 13, 2026 23:59 MT · **Points:** 25

## What to do

Open a pull request against [`uvucs3540/engine-spec`](https://github.com/uvucs3540/engine-spec) adding your name to [`spec/OWNERS.md`](https://github.com/uvucs3540/engine-spec/blob/main/spec/OWNERS.md) beside the section you want.

Read [`spec/S00-overview.md`](https://github.com/uvucs3540/engine-spec/blob/main/spec/S00-overview.md) first — it is the contract every section is written against.

## The fifteen sections

`S00`–`S03` are instructor-owned. These fifteen are yours to claim, one each. **Read the companion cheat sheet before you choose** — it is the 20% of that topic you will be specifying.

| | Section | Read first |
|---|---|---|
| `S04` | Transform hierarchy and scene graph | [scene-graph-transforms](scene-graph-transforms.md) |
| `S05` | Entity and component store | [entity-component-store](entity-component-store.md) |
| `S06` | Event bus and messaging | [game-programming-patterns](game-programming-patterns.md) |
| `S07` | Input abstraction and mapping | [game-loop-and-time](game-loop-and-time.md) |
| `S08` | Asset handles, caching, provenance | [asset-pipeline-and-provenance](asset-pipeline-and-provenance.md) |
| `S09` | Renderer seam and 2D backend | [2d-rendering](2d-rendering.md) |
| `S10` | 3D backend (WebGL2) · **heavy** | [3d-rendering-webgl](3d-rendering-webgl.md) · [shaders-and-materials](shaders-and-materials.md) |
| `S11` | Collision and spatial partition | [collision-and-spatial-partition](collision-and-spatial-partition.md) |
| `S12` | Pathfinding, navigation, steering | [pathfinding-and-navigation](pathfinding-and-navigation.md) |
| `S13` | Game AI: FSM, behavior trees, utility · **heavy** | [game-ai-behavior](game-ai-behavior.md) |
| `S14` | Procedural generation | [procedural-generation](procedural-generation.md) |
| `S15` | Narrative: dialogue graph and quest state | [storytelling-in-games](storytelling-in-games.md) |
| `S16` | Generator seam: LLM and asset providers | [local-llm-in-games](local-llm-in-games.md) |
| `S17` | Transport seam: Local and Pear · **heavy** | [netcode](netcode.md) · [p2p-pear-holepunch](p2p-pear-holepunch.md) |
| `S18` | Audio and procedural music | [audio-and-procedural-music](audio-and-procedural-music.md) |

First claim wins. The three marked **heavy** carry more work and pair well — take one with someone if you would rather.

## Choosing

Pick the one **your own game needs**. If your game leans on procedural terrain, `S14` is not a chore — it is the thing you were going to build anyway, now with a specification and a grader reading it.

Two sections are worth knowing about before you skip them. `S16` and `S17` are where this course's two hardest constraints live — a language model inside a frame budget, and multiplayer with no server. They are more interesting than they look.

## What you are signing up for

- Writing the section so **independent builds of it agree** — see [writing-a-spec-agents-can-build](writing-a-spec-agents-can-build.md)
- Shipping [conformance vectors](conformance-vectors.md) that actually test the claims
- Fixing the prose when the divergence report says builds disagreed
- A fifteen-minute talk on it, weeks 9–16

## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.

## Acceptance criteria

- PR opened against `engine-spec` and merged.
- Exactly one section claimed, unclaimed before you took it.
- One sentence on why that section, given your game.
