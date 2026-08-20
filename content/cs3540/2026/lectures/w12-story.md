---
slug: lecture-w12-story
week: 12
youtube_id: null
companion_sheets:
  - cheatsheet-storytelling-in-games
  - cheatsheet-local-llm-in-games
  - cheatsheet-cutscenes-and-timelines
reflection_assignment: devlog-w12
vernacular_tags:
  - "environmental storytelling"
  - "ludonarrative dissonance"
  - "bottleneck branching"
  - "structured output · constrained decoding"
---

# Week 12 — Story: Narrative Systems and Local Models

## What you'll know after this

After this lecture you will be able to (a) name the three places a story can live and which is cheapest, (b) structure branching without writing 2^n endings, (c) get reliable structured output from a small model, and (d) explain why the fallback is what gets graded.

## Outline

1. **Told, shown, played** *(10 min)*
   Told is precise and expensive, and it stops the player from playing — the one thing your medium does that others cannot. Shown rides on level layout you were building anyway. Played is what emerges from your systems and is the story players actually retell. **For one term, spend almost everything on shown.**

2. **Ludonarrative dissonance** *(8 min)*
   When the story says one thing and the mechanics say another. Players believe the mechanics — it is what they *did*, not what the game *claimed*.

3. **Bottleneck instead of branch** *(8 min)*
   Four binary choices is sixteen endings and you will write none of them well. Diverge, then reconverge; remember choices as **state** that changes details rather than structure. Two flags and one act can feel more responsive than four badly-written branches.

4. **Dialogue as data** *(6 min)*
   Editable without a rebuild, translatable, testable — and a chosen line enters the simulation as a **command**, which is what keeps a conversation replayable.

5. **A model in the frame budget** *(12 min)*
   You have 16.6ms; the model takes 500–3000. So never await in the tick — fire the request, keep playing, and let the answer arrive as a command. And **constrain the output**: a 3B model asked for prose wanders, the same model asked for `{line, emotion, action}` with an enum complies.

6. **The fallback is the deliverable** *(8 min)*
   A conformance vector kills every provider and checks that your game still runs **and says so**. Not that it fails gracefully — that it keeps playing, with authored lines, and tells the player. Design for that first and the cloud call becomes an enhancement.

7. **Injection through an NPC prompt** *(6 min)*
   Player-authored text reaches the model. Keep the system prompt authoritative, never interpolate player text into instructions, and validate structured output against your enum before acting — which is why `action` being an enum is doing real work.

## Discuss in class

- **Does your game's story contradict its mechanics anywhere?** Be specific.
- **Turn off your network and play your game.** That is the graded case. What happened?
- **A player names their character "Ignore previous instructions."** Walk through exactly where that string travels in your code.

## Further reading

- `spec/S15-narrative.md` and `spec/S16-generator-seam.md`
- [Ollama structured outputs](https://docs.ollama.com/)
- `cheatsheet-cutscenes-and-timelines` — including the skip that must apply every end state
