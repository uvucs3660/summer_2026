---
slug: lecture-w11-worlds
week: 11
youtube_id: null
companion_sheets:
  - cheatsheet-procedural-generation
  - cheatsheet-audio-and-procedural-music
  - cheatsheet-asset-pipeline-and-provenance
reflection_assignment: devlog-w11
vernacular_tags:
  - "value noise · octaves"
  - "cellular automata · wave function collapse"
  - "adaptive music layers"
  - "provenance manifest"
---

# Week 11 — Worlds: Procedural Generation and Sound

## What you'll know after this

After this lecture you will be able to (a) derive per-chunk seeds so generation is order-independent, (b) pick a generator by the shape of output you need, (c) build an adaptive score with gain rather than playback, and (d) say what belongs in the provenance manifest.

## Outline

1. **Seed derivation before anything else** *(8 min)*
   Draw from one global generator and your output depends on the **order** chunks were visited — which differs per machine and is a desync waiting to happen. Derive each chunk's seed from the world seed and its coordinates, with integer hashing.

2. **Four generators, four shapes** *(14 min)*
   Noise for smooth continuous fields — terrain, clouds, wind; octaves are where it starts looking real. Cellular automata for organic blobs — random fill then five smoothing passes, and **always flood-fill afterwards** or you ship an unreachable treasure room. L-systems for branching. Wave function collapse for tiles that must obey rules.

3. **The design warning** *(8 min)*
   **Infinite content gets boring faster than authored content.** A generator produces variation, not novelty, and its pattern is smaller than a designer's — so it is learned sooner. Generate the space, author the moments.

4. **Audio: schedule ahead, never on a frame** *(8 min)*
   `setTimeout` jitters by tens of milliseconds and that is audible. WebAudio has a sample-accurate clock; give it a time. And the context starts suspended — silent audio that "works on my machine" is almost always this.

5. **Adaptive music with gain** *(10 min)*
   Several layers of one loop, all playing always, gain fading with intensity. **Never start and stop layers** — a layer started mid-song lands out of phase. Two lines of ramp, and it sounds professional.

6. **Procedural music is free and on-curriculum** *(6 min)*
   A pentatonic scale makes wrong notes impossible; an envelope is what separates music from a beep. Zero bytes, deterministic, and it satisfies the procedural-generation requirement.

7. **The provenance manifest** *(6 min)*
   Model, prompt, seed, date, license, cost, phase — one entry per generated asset. Attribution record, cost ledger, supply-chain evidence, and graded artifact, in one file. Write the entry when you add the asset; nobody remembers October's prompt in December.

## Discuss in class

- **Your generator's pattern.** State it in one sentence. How many instances before a player has learned it?
- **Which of your assets could move from runtime to build time?** Everything on that side is free, instant, and replay-safe.
- **Procedural or generated?** For textures and music you now have both options. When is the diffusion model actually the better answer?

## Further reading

- [Red Blob Games](https://www.redblobgames.com/) — noise and maps, interactive
- [A Tale of Two Clocks](https://web.dev/articles/audio-scheduling) — lookahead scheduling
- `spec/S14-procedural-generation.md`, `spec/S18-audio.md`, `spec/S08-asset-handles.md`
