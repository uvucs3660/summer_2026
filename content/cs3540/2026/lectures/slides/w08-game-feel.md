---
track: game
week: 8
title: Feel
subtitle: Lies the Renderer Tells, the MDA Gap, and Watching People Play
runtime: 22
---

NOTES:
Week eight, game track, and this is the least technical lecture of the term. It is also, in my experience, the one that most changes people's games.

Everything so far has been about correctness. This week is about whether hitting something feels like hitting something — which is not a correctness property, and which no conformance vector will ever check.

---

# What you'll know after this

- Why feel lives in the **renderer** — and the one category that does not
- The juice list, ordered by **value per line of code**
- The **MDA asymmetry**: you edit mechanics, you care about aesthetics
- How to translate what a playtester says into something you can change

NOTES:
Four things, and the first is an architectural rule that keeps this whole lecture from breaking everything we built in weeks two and three.

---

# Where feel lives

![](game-feel-and-juice-where-it-lives.svg)

NOTES:
The rule first, because it is the one that costs you if you get it wrong.

Screen shake, hitstop, flash, squash, particles — all of these are lies. The world did not shake. The simulation said `hp -= 10` and everything else is presentation, told on top.

So they live in the renderer, and the moment you put one inside `tick()` you have broken replay, multiplayer, and every conformance vector at once. Hitstop inside the simulation means the simulation's notion of time now depends on whether something got hit, which means two builds with different collision resolution order have different tick counts. It is a catastrophe and it is three lines of very tempting code.

Now the right-hand column, which is the exception and the interesting part. Coyote time — a few frames of grace after walking off a ledge where jumping still works. Input buffering — a jump pressed just before landing still fires. Lenient hitboxes — the player's hurtbox smaller than their sprite.

These are not lies. They change what the game *does*. Whether you can jump is a simulation question. So they go in the simulation, which means they go in your specification and into the hash.

The thing about all three is that players never notice them when present and universally notice their absence. Nobody has ever said "I love the coyote time in this game." Plenty of people have said a game feels unresponsive and been unable to say why.

---

# Juice, by value per line

- **Hitstop** — freeze 40–80ms on impact. **Three lines. The single biggest contributor.**
- **Screen shake** — decay by `t²`, not `t`. Linear decay feels mushy.
- Flash the sprite white for two frames
- Knockback, even a few pixels
- **Easing on every UI element** — nothing in a good game moves linearly
- Squash and stretch on jump and land
- Sound with **±10% pitch variance** — without it, repeats become a machine gun

NOTES:
This list is roughly ordered by how much feel you get per line of code, and the ordering is not what people expect.

Hitstop is first and it is not close. Freeze everything for forty to eighty milliseconds on impact. Three lines. It is the difference between a hit registering as an event and a hit being a number changing, and almost nobody implements it first.

Screen shake — decay by t squared. Linear decay reads as mushy; the shake lingers past when your brain expected it to stop. Quadratic snaps.

Easing on UI is the one people skip because it is not gameplay. Nothing in a well-made game moves linearly. A health bar that jumps instantly is information; a health bar that eases is a game.

And the pitch variance one is the cheapest fix on the list. The same sound sample played twenty times in two seconds is a machine gun and your ear hears the loop immediately. Randomise the pitch by ten percent either way and it becomes twenty separate impacts.

Note that the randomisation lives in the renderer, so it uses ordinary `Math.random`, not the simulation's seeded generator. Draw from the sim's RNG for audio and the simulation now depends on how many sounds played. That is a real bug and it is on the audio cheat sheet.

---

# The MDA asymmetry

**Mechanics** — the rules you write. The only thing you can edit.

**Dynamics** — what emerges when people play them.

**Aesthetics** — what it feels like. The only thing you actually care about.

> You cannot implement "tense." You implement a mana curve and hope.

NOTES:
Here is the framework, and the reason it is worth knowing is entirely in the asymmetry.

You can only edit mechanics. Rules, numbers, systems. That is the whole surface you have.

You only care about aesthetics. Nobody sets out to build a game with a well-tuned mana curve; they set out to build a game that feels tense.

And between them is dynamics, which is what actually happens when real people meet your rules — and which you do not control. You can only influence it.

That gap is where every surprise in game design lives, in both directions. The mechanic you were proudest of produces nothing. The throwaway one produces the thing people talk about.

Read the quote and take it literally. There is no `tension` variable. You build a resource that runs out at an awkward moment and you find out.

---

# Translating feedback

![](mda-framework-translating-feedback.svg)

NOTES:
This is the most immediately useful thing in the lecture, so if you are half-listening, come back now.

A playtester says "the boss is unfair." That is an aesthetic report. It is accurate — they did feel that — and it is unactionable, because there is no unfairness parameter.

Your job is to walk it down the ladder. What actually happened? "I die before I can react to the slam." Now it is a dynamic, and it is specific enough to be wrong about.

Then to the mechanic: the slam's wind-up is eight frames. At sixty frames a second that is a hundred and thirty milliseconds, which is roughly human reaction time — so the player is not reacting, they are guessing. Make it twenty frames and the fight is transformed without touching damage or health at all.

Now read the line underneath, because it is the part that saves you weeks. The obvious fix — lower the boss's health — would not have touched the problem. The player would still die to the slam, just after fewer of them.

Players report problems accurately and propose solutions badly. Take the report. Discard the proposal. That is not disrespect; it is the correct division of labour, because they have information you do not and you have the systems view they do not.

---

# The playtest protocol

![](playtesting-protocol.svg)

NOTES:
And here is how to get that information without contaminating it.

Say nothing. This is the hard one. You will want to explain the controls, and the instant you do, you have destroyed the only chance you had to find out whether the controls are discoverable. Sit on your hands.

Write, do not talk. Timestamps and what they did, not how you felt about it.

Note every pause. Hesitation is the signal — it marks the exact place where the game failed to teach something. A player who stops for four seconds at a door is telling you the door does not look like a door.

Ask about intent afterwards, not during: "what were you trying to do there?" Not "why didn't you jump?"

And three outside testers is enough — the returns fall off fast. They must not be your teammates, because your teammates have learned where the door is and cannot unlearn it. That is the single most common way people run a useless playtest and come away reassured.

---

# Before Thursday

- **Add hitstop.** Tonight. It is three lines and it will change how your game feels.
- Find one thing in your game a player would call "unfair" and walk it down to a **mechanic**
- Line up **three outside testers** — not teammates
- `cheatsheet-game-feel-and-juice`, `cheatsheet-mda-framework`, `cheatsheet-playtesting`

Thursday, AI: **Reading the Divergence Report.** The Act II response is due **Sun Oct 19.**

NOTES:
Do the hitstop tonight. Genuinely — it is three lines, and the ratio of effect to effort is the best in the course.

The second one is the discussion. Find the unfair thing, and bring the walk-down: aesthetic, dynamic, mechanic. I want to see the middle step, because that is the one people skip.

And start lining up testers now, because "three outside testers" is a scheduling problem, not a technical one, and it is due in November.

Thursday is the divergence report, and your Act II response is due on the nineteenth.
