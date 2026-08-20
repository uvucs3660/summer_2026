---
slug: lecture-w08-feel
week: 8
youtube_id: null
companion_sheets:
  - cheatsheet-game-feel-and-juice
  - cheatsheet-mda-framework
  - cheatsheet-playtesting
reflection_assignment: devlog-w08
vernacular_tags:
  - "hitstop · screen shake · squash and stretch"
  - "coyote time · input buffering"
  - "Mechanics · Dynamics · Aesthetics"
  - "telegraphing"
---

# Week 8 — Feel: Juice, MDA, and Playtesting

## What you'll know after this

After this lecture you will be able to (a) list eight cheap effects that make a hit land, (b) say which of them belong in the simulation and which do not, (c) translate a playtest complaint back to a mechanic, and (d) run a session that produces evidence instead of compliments.

## Outline

1. **The architectural rule first** *(6 min)*
   Feel lives in the **renderer**. Screen shake, hitstop, and squash are visual lies told on top of a deterministic simulation. Put any of them inside `tick()` and you have broken replay, multiplayer, and your conformance vectors at once. The simulation says `hp -= 10`; everything else is presentation.

2. **The list, by value per line** *(12 min)*
   Hitstop — freeze 40–80ms on impact, three lines, the single biggest contributor. Screen shake decaying by `t²`, not `t`. Flash. Knockback. Easing on every UI element. Squash and stretch. Particles. Sound with ±10% pitch variance, or repeats become a machine gun.

3. **Forgiveness mechanics — the exception** *(8 min)*
   Coyote time, input buffering, and lenient hitboxes change what the game *does*, so they belong in the simulation and must be specified. Players never notice them and universally notice their absence — the game feels "unresponsive" and nobody can say why.

4. **MDA: the asymmetry** *(12 min)*
   You can only edit **mechanics**. You only care about **aesthetics**. **Dynamics** is the gap, and it is where the surprises live. You cannot implement "tense" — you implement a mana curve and hope.

5. **Translating feedback** *(10 min)*
   "The boss is unfair" (aesthetic) → "I die before I can react to the slam" (dynamic) → "wind-up is 8 frames" (mechanic). The obvious fix — less boss health — would not have touched the problem. Players report problems accurately and propose solutions badly.

6. **The playtest protocol** *(8 min)*
   Say nothing. Write, do not talk. Note every pause. Ask about intent afterwards. Three outside testers is enough, and they must not be your teammates — those have learned where the door is.

## Discuss in class

- **Record thirty seconds of your game and thirty of a game you admire, sound off.** The gap is almost always in the §2 list.
- **Sitting on your hands is the hardest part of a playtest.** Why is helping so tempting, and what exactly does it destroy?
- **Name the aesthetic you are aiming for**, then the dynamic that would produce it, then the mechanic. Where does the chain break?

## Further reading

- [MDA: A Formal Approach to Game Design](https://users.cs.northwestern.edu/~hunicke/MDA.pdf) — eight pages
- [Juice it or lose it](https://www.youtube.com/watch?v=Fy0aCDmgnxg) — twelve minutes, the canonical demo
- Steve Swink, *Game Feel*
